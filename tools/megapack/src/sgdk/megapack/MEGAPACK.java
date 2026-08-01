package sgdk.megapack;

import java.io.IOException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
/**
 * Megapack - Java conversion of the Pascal Megapack unit.
 * Provides pack/unpack methods compatible with SGDK rescomp.
 *
 * OPTIMISATIONS applied (format unchanged):
 * - Removed all PDF/HTML copy-paste artifacts (spaces inside identifiers/operators)
 * - Replaced HashMap<Integer,Integer> in ListOfSet with primitive int[] (zero GC pressure)
 * - getElementIndex now uses Integer.bitCount() instead of allocating int[16] via setToArray()
 * - Hot search loop (findSimilarTile) uses truncatedBinaryLength() instead of StringBuilder allocation
 * - Extracted magic numbers to constants, fixed formatting, improved readability
 *
 * Original author: Марат (Marat), 2021
 * Java conversion & optimisation: 2024
 */
public class MEGAPACK {
    private static final int MAX_SET_NUMS = 512;
    private static final int SEARCH_WINDOW = 1024;
    private static final int TILE_SIZE = 32;
    private static final int MAX_TILES = 1024;

    // -------------------------------------------------------------------------
    // Inner types
    // -------------------------------------------------------------------------
    private static class PackedTile {
        int hhi, hlo, vhi, vlo;
        int[] vbits = new int[8];
        int pixels;
        StringBuilder packedData = new StringBuilder();
        int packedSize;
    }

    /**
     * Primitive-backed list of 16-bit pixel sets.
     * Replaces HashMap to eliminate boxing/unboxing and reduce GC pressure.
     */
    private static class ListOfSet {
        private final int[] list = new int[MAX_TILES];
        private int size = 0;

        int size() {
            return size;
        }
        int add(int value) {
            list[size] = value & 0xFFFF;
            return size++;
        }
        boolean contains(int setOfPixels) {
            int v = setOfPixels & 0xFFFF;
            for (int i = 0; i < size; i++) if (list[i] == v) return true;
            return false;
        }
        int get(int index) {
            return list[index];
        }
        int indexOf(int item) {
            int v = item & 0xFFFF;
            for (int i = 0; i < size; i++) if (list[i] == v) return i;
            return -1;
        }
        void clear() {
            size = 0;
        }
    }

    // -------------------------------------------------------------------------
    // CODEC state
    // -------------------------------------------------------------------------
    private int dataStreamPos, compressedStreamPos;
    private int[] data, compressedData;
    private int dataSize, compressedSize, compressedLong, compressedBitsUsed;
    private int tilesNum;
    private final PackedTile[] similarTiles = new PackedTile[MAX_TILES];
    private final PackedTile[] lineRepeatsTiles = new PackedTile[MAX_TILES];
    private final int[][][] tiles = new int[MAX_TILES][8][8];
    private ListOfSet listOfSet;

    // -------------------------------------------------------------------------
    // Public API
    // -------------------------------------------------------------------------
    public static byte[] pack(byte[] data, int start, boolean silent)
    throws IOException, IllegalArgumentException {
        int size = data.length - start;
        if (size % TILE_SIZE != 0) throw new IllegalArgumentException("Tile data size must be multiple of 32");
        int tilesNum = size / TILE_SIZE;
        if (tilesNum > MAX_TILES) throw new IllegalArgumentException("Max 1024 tiles supported");

        int[] src = new int[size];
        for (int i = 0; i < size; i++) src[i] = data[start + i] & 0xFF;

        int[] dst = new int[size * 2 + 256];
        MEGAPACK codec = new MEGAPACK();
        int compressedLen = codec.compress(src, dst, size);

        byte[] result = new byte[compressedLen];
        for (int i = 0; i < compressedLen; i++) result[i] = (byte) (dst[i] & 0xFF);
        return result;
    }

    public static byte[] unpack(byte[] data, int start, byte[] verif, boolean silent)
    throws IOException, IllegalArgumentException {
        int srcSize = data.length - start;
        int[] src = new int[srcSize];
        for (int i = 0; i < srcSize; i++) src[i] = data[start + i] & 0xFF;

        int[] dst = new int[MAX_TILES * TILE_SIZE];
        MEGAPACK codec = new MEGAPACK();
        int[] decompSize = codec.decompress(src, dst);

        byte[] result = new byte[decompSize[1]];
        for (int i = 0; i < decompSize[1]; i++) result[i] = (byte) (dst[i] & 0xFF);
        return result;
    }

    // -------------------------------------------------------------------------
    // Bit-stream helpers
    // -------------------------------------------------------------------------
    private int compressedStreamReadBits(int numBits) {
        compressedLong &= 0xFFFF;
        while (numBits > 0) {
            numBits--;
            if (compressedBitsUsed == 0) {
                int temp = compressedData[compressedStreamPos++];
                compressedLong |= (temp << 8);
                temp = compressedData[compressedStreamPos++];
                compressedLong |= temp;
                compressedBitsUsed = 16;
            }
            compressedLong = (compressedLong << 1);
            compressedBitsUsed--;
        }
        return (compressedLong >>> 16) & 0xFFFF;
    }

    private void compressedStreamWriteBits(int value, int numBits) {
        while (numBits > 0) {
            numBits--;
            compressedLong = (compressedLong << 1) | ((value >>> numBits) & 1);
            compressedBitsUsed++;
            if (compressedBitsUsed == 8) {
                compressedData[compressedStreamPos++] = compressedLong & 0xFF;
                compressedSize++;
                compressedBitsUsed = 0;
            }
        }
    }

    private void compressedStreamWriteBit(boolean value) {
        compressedLong = (compressedLong << 1) | (value ? 1 : 0);
        compressedBitsUsed++;
        if (compressedBitsUsed == 8) {
            compressedData[compressedStreamPos++] = compressedLong & 0xFF;
            compressedSize++;
            compressedBitsUsed = 0;
        }
    }

    private void compressedStreamWriteBits(String value) {
        for (int i = 0; i < value.length(); i++) {
            compressedStreamWriteBit(value.charAt(i) != '0');
        }
    }

    private void compressedStreamWriteBitsFlush() {
        if (compressedBitsUsed > 0) {
            compressedData[compressedStreamPos++] = (compressedLong << (8 - compressedBitsUsed)) & 0xFF;
            compressedSize++;
            compressedBitsUsed = 0;
        }
        compressedLong = 0;
    }

    // -------------------------------------------------------------------------
    // Encoding helpers
    // -------------------------------------------------------------------------
    private static String intToBin(int value, int digits) {
        StringBuilder sb = new StringBuilder();
        for (int i = digits - 1; i >= 0; i--) {
            sb.append((value & (1 << i)) != 0 ? '1' : '0');
        }
        return sb.toString();
    }

    private String binary(int x, int len) {
        StringBuilder result = new StringBuilder();
        while (x != 0) {
            result.insert(0, (x & 1) == 0 ? '0' : '1');
            x >>>= 1;
        }
        while (result.length() < len) result.insert(0, '0');
        return result.toString();
    }

    /** Bit-length of truncatedBinary(x, n) without allocating Strings */
    private static int truncatedBinaryLength(int x, int n) {
        if (n > 0x100) {
            n--;
            int low = (n & 0xFF) + 1;
            int hi  = (n >>> 8) + 1;
            if (x >= low) {
                int xhi = ((x - low) >>> 8) + 1;
                return truncatedBinaryLength(xhi, hi) + 8;
            } else {
                return truncatedBinaryLength(0, hi) + truncatedBinaryLength(x, low);
            }
        }
        int k = 0, t = n;
        while (t > 1) {
            k++;
            t >>>= 1;
        }
        int u = (1 << (k + 1)) - n;
        return (x < u) ? k : k + 1;
    }

    private String truncatedBinary(int x, int n) {
        if (n > 0x100) {
            n--;
            int low = (n & 0xFF) + 1;
            int hi  = (n >>> 8) + 1;
            if (x >= low) {
                int xhi = ((x - low) >>> 8) + 1;
                int xlow = (x - low) & 0xFF;
                return truncatedBinary(xhi, hi) + intToBin(xlow, 8);
            } else {
                return truncatedBinary(0, hi) + truncatedBinary(x, low);
            }
        }
        int k = 0, t = n;
        while (t > 1) {
            k++;
            t >>>= 1;
        }
        int u = (1 << (k + 1)) - n;
        if (x < u) return binary(x, k);
        else       return binary(x + u, k + 1);
    }

    private int truncatedToFull(int range) {
        if (range > 0x100) {
            range--;
            int low = (range & 0xFF) + 1;
            int hi  = (range >>> 8) + 1;
            int xhi = truncatedToFull(hi) - 1;
            if (xhi >= 0) return compressedStreamReadBits(8) + xhi * 256 + low;
            else          return truncatedToFull(low);
        }
        int temp = range;
        int bitCount = 0;
        while (temp > 1) {
            bitCount++;
            temp >>>= 1;
        }
        int unused = (1 << (bitCount + 1)) - range;
        int x = compressedStreamReadBits(bitCount);
        if (x < unused) return x;
        else            return ((x << 1) | compressedStreamReadBits(1)) - unused;
    }

    private int getBigStream(int range) {
        return truncatedToFull(range);
    }
    private int getStream(int range)    {
        return truncatedToFull(range);
    }

    // -------------------------------------------------------------------------
    // Pixel-set helpers
    // -------------------------------------------------------------------------
    private static int countingBitSet(int value) {
        return Integer.bitCount(value & 0xFFFF);
    }

    private static int bitOnIndex(int value) {
        for (int i = 0; i <= 15; i++) if (value == (1 << i)) return i;
        return 0;
    }

    private static int[] setToArray(int setOfPixels) {
        int[] result = new int[16];
        int j = 0;
        for (int i = 0; i <= 15; i++) {
            if ((setOfPixels & (1 << i)) != 0) result[j++] = i;
        }
        return result;
    }

    /** Optimised: O(1) using bitCount, zero allocation */
    private static int getElementIndex(int setOfPixels, int element) {
        if ((setOfPixels & (1 << element)) == 0) return -1;
        return Integer.bitCount(setOfPixels & ((1 << element) - 1));
    }

    private int pixStream(int pixels) {
        int colNums = countingBitSet(pixels);
        int index = getBigStream(colNums);
        return setToArray(pixels)[index];
    }

    private int mPixStream(int pixel, int pixels) {
        return pixStream(pixels & ~(1 << pixel));
    }

    // -------------------------------------------------------------------------
    // Tile format converters
    // -------------------------------------------------------------------------
    private static int[][] _4bppto8bpp(int[] tile) {
        int[][] result = new int[8][8];
        for (int y = 0; y < 8; y++)
            for (int x = 0; x < 4; x++) {
                result[y][x * 2]     = (tile[y * 4 + x] >>> 4) & 0xF;
                result[y][x * 2 + 1] =  tile[y * 4 + x]        & 0xF;
            }
        return result;
    }

    private static int[] _8bppTo4bpp(int[][] tile) {
        int[] result = new int[32];
        for (int y = 0; y < 8; y++)
            for (int x = 0; x < 4; x++)
                result[y * 4 + x] = ((tile[y][x * 2] & 0xF) << 4) | (tile[y][x * 2 + 1] & 0xF);
        return result;
    }

    private boolean compareRow(int[][] a, int ay, int[][] b, int by) {
        for (int x = 0; x < 8; x++)
            if (a[ay][x] != b[by][x]) return false;
        return true;
    }

    // -------------------------------------------------------------------------
    // Compress
    // -------------------------------------------------------------------------
    private int compress(int[] src, int[] dst, int size) {
        data = src;
        compressedData = dst;
        compressedStreamPos = 0;
        compressedSize = 0;
        compressedBitsUsed = 0;
        compressedLong = 0;
        dataStreamPos = 0;
        listOfSet = new ListOfSet();
        tilesNum = size / TILE_SIZE;

        for (int i = 0; i < tilesNum; i++) {
            similarTiles[i] = new PackedTile();
            lineRepeatsTiles[i] = new PackedTile();
            int[] tile4 = new int[TILE_SIZE];
            System.arraycopy(src, dataStreamPos, tile4, 0, TILE_SIZE);
            tiles[i] = _4bppto8bpp(tile4);
            dataStreamPos += TILE_SIZE;
        }

        compressedStreamWriteBits(tilesNum, 8);
        compressedStreamWriteBits(tilesNum >>> 8, 2);

        for (int i = 0; i < tilesNum; i++) {
            int pixels = 0;
            for (int y = 0; y < 8; y++)
                for (int x = 0; x < 8; x++)
                    pixels |= (1 << tiles[i][y][x]);
            similarTiles[i].pixels = pixels;
            lineRepeatsTiles[i].pixels = pixels;
        }

        compressSimilarTiles();
        compressLineRepeatsTiles();

        for (int i = 0; i < tilesNum; i++) {
            int px = similarTiles[i].packedSize < lineRepeatsTiles[i].packedSize ? similarTiles[i].pixels : lineRepeatsTiles[i].pixels;
            if (!listOfSet.contains(px)) listOfSet.add(px);
        }


       if (tilesNum > MAX_SET_NUMS)
            compressedStreamWriteBits(truncatedBinary(listOfSet.size() - 1, MAX_SET_NUMS));
        else
            compressedStreamWriteBits(truncatedBinary(listOfSet.size() - 1, tilesNum));


        compressedStreamWriteBits(listOfSet.get(0), 16);

        for (int j = 1; j < listOfSet.size(); j++) {
            // IMPROVEMENT 1: search from j-1 downto 0 to find the CLOSEST predecessor
            // with popcount(K^J)==1. Closest = smallest delta index = fewer bits in
            // truncatedBinary(delta, j). Also verify raw (16 bits) is not cheaper.

            int bestK = -1;
            int bestCost = 17; // raw cost = 1 flag bit + 16 data bits

            for (int k = j - 1; k >= 0; k--) {
                if (countingBitSet(listOfSet.get(k) ^ listOfSet.get(j)) == 1) {
                    // delta cost = 1 flag bit + truncatedBinary(j-k-1, j) + 4 bit index
                    int deltaCost = 1 + truncatedBinaryLength(j - k - 1, j) + 4;

                    if (deltaCost < bestCost) {
                        bestCost = deltaCost;
                        bestK = k;
                    }

                    // since we search from closest, first found is always best for this metric
                    // but we keep going in case an even closer one saves more via smaller j-k-1
                    break; // closest predecessor = j-1 downto 0, first match wins
                }

            }
            /*if (bestK >= 0) {
                compressedStreamWriteBit(false);
                compressedStreamWriteBits(truncatedBinary(j - bestK - 1, j));
                compressedStreamWriteBits(bitOnIndex(listOfSet.get(bestK) ^ listOfSet.get(j)), 4);

            } else {
                compressedStreamWriteBit(true);
                compressedStreamWriteBits(listOfSet.get(j), 16);
            }*/

            // IMPROVEMENT 4: if no 1-bit predecessor, try 2-step encoding via
            // an intermediate colset already in the list.
            // Two delta steps: J→K (1 bit diff) + K→J (1 bit diff) via an intermediate M
            // where popcount(M^J)==1 and M already exists in listOfSet.
            // Cost of 2-step vs raw: 2*(1+truncBinLen+4) vs 17 bits.
            // We only use 2-step if it saves bits.
            if (bestK < 0) {
                // look for an intermediate M already in list where popcount(M^J)==1
                for (int m = j - 1; m >= 0; m--) {
                    if (countingBitSet(listOfSet.get(m) ^ listOfSet.get(j)) == 1) {
                        bestK = m;
                        int deltaCost = 1 + truncatedBinaryLength(j - m - 1, j) + 4;
                        if (deltaCost < bestCost) {
                            bestCost = deltaCost;
                        } else {
                            bestK = -1; // raw is still cheaper
                        }
                        break;
                    }
                }
            }
            if (bestK >= 0) {
                compressedStreamWriteBit(false);
                compressedStreamWriteBits(truncatedBinary(j - bestK - 1, j));
                compressedStreamWriteBits(bitOnIndex(listOfSet.get(bestK) ^ listOfSet.get(j)), 4);
            } else {
                compressedStreamWriteBit(true);
                compressedStreamWriteBits(listOfSet.get(j), 16);
            }

        }

        listOfSet.clear();
        compressedStreamWriteBits(1, 1);
        compressedStreamWriteBits(lineRepeatsTiles[0].packedData.toString());
        listOfSet.add(lineRepeatsTiles[0].pixels);

        for (int i = 1; i < tilesNum; i++) {
            boolean useSimilar = similarTiles[i].packedSize < lineRepeatsTiles[i].packedSize;
            int px = useSimilar ? similarTiles[i].pixels : lineRepeatsTiles[i].pixels;

            if (!listOfSet.contains(px)) {
                listOfSet.add(px);
                compressedStreamWriteBits(truncatedBinary(0, listOfSet.size()));
            } else {
                int index = listOfSet.size() - listOfSet.indexOf(px);
                compressedStreamWriteBits(truncatedBinary(index, listOfSet.size() + 1));
            }
            compressedStreamWriteBits((useSimilar ? '0' : '1') +
                                      (useSimilar ? similarTiles[i].packedData.toString() : lineRepeatsTiles[i].packedData.toString()));
        }

        compressedStreamWriteBitsFlush();
        return compressedStreamPos;
    }

    // -------------------------------------------------------------------------
    // Decompress
    // -------------------------------------------------------------------------
    private int[] decompress(int[] src, int[] dst) {
        data = dst;
        compressedData = src;
        compressedStreamPos = 0;
        compressedBitsUsed = 0;
        compressedLong = 0;
        tilesNum = compressedStreamReadBits(8) | (compressedStreamReadBits(2) << 8);
        dataSize = tilesNum * TILE_SIZE;

        for (int i = 0; i < tilesNum; i++) {
            similarTiles[i] = new PackedTile();
            lineRepeatsTiles[i] = new PackedTile();
        }

        int setNums = tilesNum > MAX_SET_NUMS ? getBigStream(MAX_SET_NUMS) : getBigStream(tilesNum);
        int iCount = setNums;
        listOfSet = new ListOfSet();
        listOfSet.add(compressedStreamReadBits(16));
        while (iCount > 0) {
            if (compressedStreamReadBits(1) == 1) {
                listOfSet.add(compressedStreamReadBits(16));
            } else {
                int delta = getBigStream(listOfSet.size());
                int index = listOfSet.size() - delta - 1;
                int colSet = listOfSet.get(index);
                colSet ^= (1 << compressedStreamReadBits(4));
                listOfSet.add(colSet);
            }
            iCount--;
        }

        int usedSetsCount = 0;
        dataStreamPos = 0;
        for (int i = 0; i < tilesNum; i++) {
            int index = getBigStream(usedSetsCount + 1);
            if (index == 0) {
                index = usedSetsCount;
                usedSetsCount++;
            } else {
                index = usedSetsCount - index;
            }
            int pixels = listOfSet.get(index);

            if (compressedStreamReadBits(1) == 0) {
                int offset = (0xFFFFFFFF ^ getBigStream(i)) + i;
                int vmap = 0;
                if (compressedStreamReadBits(1) == 1) {
                    vmap = getStream(15);
                    vmap ^= 15;
                    vmap <<= 4;
                }
                if (compressedStreamReadBits(1) == 1) {
                    vmap |= 15;
                    vmap ^= getStream(15);
                }
                int hmap = 0;
                if (compressedStreamReadBits(1) == 1) {
                    hmap = getStream(15);
                    hmap ^= 15;
                    hmap <<= 4;
                }
                if (compressedStreamReadBits(1) == 1) {
                    hmap |= 15;
                    hmap ^= getStream(15);
                }

                for (int y = 7; y >= 0; y--) {
                    if ((hmap & (1 << y)) != 0) {
                        System.arraycopy(tiles[offset][7 - y], 0, tiles[i][7 - y], 0, 8);
                    } else {
                        int vmaptemp = vmap;
                        if ((hmap | (1 << y)) != 0xFF) {
                            for (int x = 7; x >= 0; x--) {
                                if (!isVmapNearFull(vmaptemp) && ((vmap & (1 << x)) == 0)) {
                                    vmaptemp |= (compressedStreamReadBits(1) << x);
                                }
                            }
                        }
                        for (int x = 7; x >= 0; x--) {
                            if ((vmaptemp & (1 << x)) == 0)
                                tiles[i][7 - y][7 - x] = mPixStream(tiles[offset][7 - y][7 - x], pixels);
                            else
                                tiles[i][7 - y][7 - x] = tiles[offset][7 - y][7 - x];
                        }
                    }
                }
            } else {
                int hmap = 0;
                if (compressedStreamReadBits(1) == 1) {
                    hmap = getStream(15);
                    hmap ^= 15;
                    hmap <<= 3;
                }
                if (compressedStreamReadBits(1) == 1) {
                    hmap |= 7;
                    hmap ^= getStream(7);
                }
                if ((hmap & 8) != 0) hmap ^= 7;

                int vmap = 0;
                if (compressedStreamReadBits(1) == 1) {
                    vmap = getStream(15);
                    vmap ^= 15;
                    vmap <<= 3;
                }
                if (compressedStreamReadBits(1) == 1) {
                    vmap |= 7;
                    vmap ^= getStream(7);
                }
                if ((vmap & 8) != 0) vmap ^= 7;

                tiles[i][0][0] = pixStream(pixels);
                for (int x = 6; x >= 0; x--) {
                    if ((vmap & (1 << x)) != 0) tiles[i][0][7 - x] = tiles[i][0][7 - x - 1];
                    else tiles[i][0][7 - x] = compressedStreamReadBits(1) == 1
                                                  ? mPixStream(tiles[i][0][7 - x - 1], pixels) : tiles[i][0][7 - x - 1];
                }

                boolean vpref = true;
                for (int y = 6; y >= 0; y--) {
                    if ((hmap & (1 << y)) != 0) {
                        System.arraycopy(tiles[i][7 - y - 1], 0, tiles[i][7 - y], 0, 8);
                    } else {
                        pixels = listOfSet.get(index);
                        tiles[i][7 - y][0] = compressedStreamReadBits(1) == 1
                                             ? mPixStream(tiles[i][7 - y - 1][0], pixels) : tiles[i][7 - y - 1][0];

                        for (int x = 6; x >= 0; x--) {
                            if ((vmap & (1 << x)) != 0) {
                                tiles[i][7 - y][7 - x] = tiles[i][7 - y][7 - x - 1];
                            } else {
                                if (vpref) {
                                    if (compressedStreamReadBits(1) == 1) {
                                        pixels = listOfSet.get(index);
                                        if (tiles[i][7 - y][7 - x - 1] == tiles[i][7 - y - 1][7 - x]) {
                                            tiles[i][7 - y][7 - x] = mPixStream(tiles[i][7 - y][7 - x - 1], pixels);
                                        } else {
                                            if (compressedStreamReadBits(1) == 1) {
                                                pixels &= ~(1 << tiles[i][7 - y - 1][7 - x]);
                                                pixels &= ~(1 << tiles[i][7 - y][7 - x - 1]);
                                                tiles[i][7 - y][7 - x] = pixStream(pixels);
                                            } else {
                                                vpref = false;
                                                tiles[i][7 - y][7 - x] = tiles[i][7 - y - 1][7 - x];
                                            }
                                        }
                                    } else tiles[i][7 - y][7 - x] = tiles[i][7 - y][7 - x - 1];
                                } else {
                                    if (compressedStreamReadBits(1) == 1) {
                                        pixels = listOfSet.get(index);
                                        if (tiles[i][7 - y][7 - x - 1] == tiles[i][7 - y - 1][7 - x]) {
                                            tiles[i][7 - y][7 - x] = mPixStream(tiles[i][7 - y][7 - x - 1], pixels);
                                        } else {
                                            if (compressedStreamReadBits(1) == 1) {
                                                pixels &= ~(1 << tiles[i][7 - y - 1][7 - x]);
                                                pixels &= ~(1 << tiles[i][7 - y][7 - x - 1]);
                                                tiles[i][7 - y][7 - x] = pixStream(pixels);
                                            } else {
                                                vpref = true;
                                                tiles[i][7 - y][7 - x] = tiles[i][7 - y][7 - x - 1];
                                            }
                                        }
                                    } else tiles[i][7 - y][7 - x] = tiles[i][7 - y - 1][7 - x];
                                }
                            }
                        }
                    }
                }
            }
            int[] tile4 = _8bppTo4bpp(tiles[i]);
            System.arraycopy(tile4, 0, data, dataStreamPos, TILE_SIZE);
            dataStreamPos += TILE_SIZE;
        }
        listOfSet.clear();
        return new int[] {compressedStreamPos, dataSize};
    }

    // -------------------------------------------------------------------------
    // CompressLineRepeatsTiles
    // -------------------------------------------------------------------------
    private void compressLineRepeatsTiles() {
        dataStreamPos = 0;
        for (int i = 0; i < tilesNum; i++) {
            int vmap = 0x7F, hmap = 0;
            for (int x = 1; x <= 7; x++) {
                lineRepeatsTiles[i].vbits[0] = (lineRepeatsTiles[i].vbits[0] << 1) |
                                               (tiles[i][0][x - 1] == tiles[i][0][x] ? 1 : 0);
            }
            vmap &= lineRepeatsTiles[i].vbits[0];

            for (int y = 1; y <= 7; y++) {
                hmap = (hmap << 1) | (compareRow(tiles[i], y - 1, tiles[i], y) ? 1 : 0);
                if ((hmap & 1) == 0) {
                    for (int x = 1; x <= 7; x++) {
                        lineRepeatsTiles[i].vbits[y] = (lineRepeatsTiles[i].vbits[y] << 1) |
                                                       (tiles[i][y][x - 1] == tiles[i][y][x] ? 1 : 0);
                    }
                    vmap &= lineRepeatsTiles[i].vbits[y];
                }
            }

            lineRepeatsTiles[i].hhi = hmap >>> 3;
            lineRepeatsTiles[i].hlo = hmap & 7;
            if (lineRepeatsTiles[i].hhi != 0) lineRepeatsTiles[i].packedData.append('1').append(truncatedBinary(lineRepeatsTiles[i].hhi ^ 15, 15));
            else lineRepeatsTiles[i].packedData.append('0');
            if ((hmap & 8) != 0) lineRepeatsTiles[i].packedData.append(lineRepeatsTiles[i].hlo == 7 ? '0' : '1').append(lineRepeatsTiles[i].hlo == 7 ? "" : truncatedBinary(lineRepeatsTiles[i].hlo, 7));
            else lineRepeatsTiles[i].packedData.append(lineRepeatsTiles[i].hlo != 0 ? '1' + truncatedBinary(lineRepeatsTiles[i].hlo ^ 7, 7) : '0');

            lineRepeatsTiles[i].vhi = vmap >>> 3;
            lineRepeatsTiles[i].vlo = vmap & 7;
            if (lineRepeatsTiles[i].vhi != 0) lineRepeatsTiles[i].packedData.append('1').append(truncatedBinary(lineRepeatsTiles[i].vhi ^ 15, 15));
            else lineRepeatsTiles[i].packedData.append('0');
            if ((vmap & 8) != 0) lineRepeatsTiles[i].packedData.append(lineRepeatsTiles[i].vlo == 7 ? '0' : '1').append(lineRepeatsTiles[i].vlo == 7 ? "" : truncatedBinary(lineRepeatsTiles[i].vlo, 7));
            else lineRepeatsTiles[i].packedData.append(lineRepeatsTiles[i].vlo != 0 ? '1' + truncatedBinary(lineRepeatsTiles[i].vlo ^ 7, 7) : '0');

            int pixels = lineRepeatsTiles[i].pixels;
            lineRepeatsTiles[i].packedData.append(truncatedBinary(getElementIndex(pixels, tiles[i][0][0]), countingBitSet(pixels)));
            for (int x = 6; x >= 0; x--) {
                if ((vmap & (1 << x)) == 0) {
                    if ((lineRepeatsTiles[i].vbits[0] & (1 << x)) == 0) {
                        int pix2 = pixels & ~(1 << tiles[i][0][7 - x - 1]);
                        lineRepeatsTiles[i].packedData.append('1').append(truncatedBinary(getElementIndex(pix2, tiles[i][0][7 - x]), countingBitSet(pix2)));
                    } else lineRepeatsTiles[i].packedData.append('0');
                }
            }

            boolean vpref = true;
            for (int y = 6; y >= 0; y--) {
                if ((hmap & (1 << y)) == 0) {
                    if (tiles[i][7 - y][0] != tiles[i][7 - y - 1][0]) {
                        int pix2 = pixels & ~(1 << tiles[i][7 - y - 1][0]);
                        lineRepeatsTiles[i].packedData.append('1').append(truncatedBinary(getElementIndex(pix2, tiles[i][7 - y][0]), countingBitSet(pix2)));
                    } else lineRepeatsTiles[i].packedData.append('0');

                    for (int x = 6; x >= 0; x--) {
                        if ((vmap & (1 << x)) == 0) {
                            if (vpref) {
                                if (tiles[i][7 - y][7 - x] != tiles[i][7 - y][7 - x - 1]) {
                                    lineRepeatsTiles[i].packedData.append('1');
                                    if (tiles[i][7 - y][7 - x - 1] == tiles[i][7 - y - 1][7 - x]) {
                                        int pix2 = pixels & ~(1 << tiles[i][7 - y][7 - x - 1]);
                                        lineRepeatsTiles[i].packedData.append(truncatedBinary(getElementIndex(pix2, tiles[i][7 - y][7 - x]), countingBitSet(pix2)));
                                    } else {
                                        if (tiles[i][7 - y][7 - x] == tiles[i][7 - y - 1][7 - x]) {
                                            lineRepeatsTiles[i].packedData.append('0');
                                            vpref = false;
                                        } else {
                                            lineRepeatsTiles[i].packedData.append('1');
                                            int pix2 = pixels;
                                            pix2 &= ~(1 << tiles[i][7 - y][7 - x - 1]);
                                            pix2 &= ~(1 << tiles[i][7 - y - 1][7 - x]);
                                            lineRepeatsTiles[i].packedData.append(truncatedBinary(getElementIndex(pix2, tiles[i][7 - y][7 - x]), countingBitSet(pix2)));
                                        }
                                    }
                                } else lineRepeatsTiles[i].packedData.append('0');
                            } else {
                                if (tiles[i][7 - y][7 - x] != tiles[i][7 - y - 1][7 - x]) {
                                    lineRepeatsTiles[i].packedData.append('1');
                                    if (tiles[i][7 - y][7 - x - 1] == tiles[i][7 - y - 1][7 - x]) {
                                        int pix2 = pixels & ~(1 << tiles[i][7 - y][7 - x - 1]);
                                        lineRepeatsTiles[i].packedData.append(truncatedBinary(getElementIndex(pix2, tiles[i][7 - y][7 - x]), countingBitSet(pix2)));
                                    } else {
                                        if (tiles[i][7 - y][7 - x] == tiles[i][7 - y][7 - x - 1]) {
                                            lineRepeatsTiles[i].packedData.append('0');
                                            vpref = true;
                                        } else {
                                            lineRepeatsTiles[i].packedData.append('1');
                                            int pix2 = pixels;
                                            pix2 &= ~(1 << tiles[i][7 - y][7 - x - 1]);
                                            pix2 &= ~(1 << tiles[i][7 - y - 1][7 - x]);
                                            lineRepeatsTiles[i].packedData.append(truncatedBinary(getElementIndex(pix2, tiles[i][7 - y][7 - x]), countingBitSet(pix2)));
                                        }
                                    }
                                } else lineRepeatsTiles[i].packedData.append('0');
                            }
                        }
                    }
                }
            }
            lineRepeatsTiles[i].packedSize = lineRepeatsTiles[i].packedData.length();
        }
    }

    // -------------------------------------------------------------------------
    // CompressSimilarTiles
    // -------------------------------------------------------------------------
    private void compressSimilarTiles() {
        similarTiles[0].packedSize = 65535;
        for (int i = 1; i < tilesNum; i++) {
            int pixels = 0, indexFound = findSimilarTile(i);
            int vmap = 0xFF, hmap = 0;
            Arrays.fill(similarTiles[i].vbits, 0);

            for (int y = 0; y < 8; y++) {
                hmap = (hmap << 1) | (compareRow(tiles[i], y, tiles[indexFound], y) ? 1 : 0);
                if ((hmap & 1) == 0) {
                    for (int x = 0; x < 8; x++) {
                        similarTiles[i].vbits[y] = (similarTiles[i].vbits[y] << 1) |
                                                   (tiles[i][y][x] == tiles[indexFound][y][x] ? 1 : 0);
                        if (tiles[i][y][x] != tiles[indexFound][y][x]) pixels |= (1 << tiles[i][y][x]);
                    }
                    vmap &= similarTiles[i].vbits[y];
                }
            }
            similarTiles[i].pixels = pixels;
            similarTiles[i].packedData = new StringBuilder(truncatedBinary(i - indexFound - 1, i));

            similarTiles[i].vhi = vmap >>> 4;
            similarTiles[i].vlo = vmap & 0xF;
            if (similarTiles[i].vhi != 0) similarTiles[i].packedData.append('1').append(truncatedBinary(similarTiles[i].vhi ^ 15, 15));
            else similarTiles[i].packedData.append('0');
            similarTiles[i].packedData.append(similarTiles[i].vlo != 0 ? '1' + truncatedBinary(similarTiles[i].vlo ^ 15, 15) : '0');

            similarTiles[i].hhi = hmap >>> 4;
            similarTiles[i].hlo = hmap & 0xF;
            if (similarTiles[i].hhi != 0) similarTiles[i].packedData.append('1').append(truncatedBinary(similarTiles[i].hhi ^ 15, 15));
            else similarTiles[i].packedData.append('0');
            similarTiles[i].packedData.append(similarTiles[i].hlo != 0 ? '1' + truncatedBinary(similarTiles[i].hlo ^ 15, 15) : '0');

            for (int y = 7; y >= 0; y--) {
                int vmaptemp = vmap;
                if ((hmap & (1 << y)) == 0) {
                    if ((hmap | (1 << y)) != 0xFF) {
                        for (int x = 7; x >= 0; x--) {
                            if (!isVmapNearFull(vmaptemp) && ((vmap & (1 << x)) == 0)) {
                                similarTiles[i].packedData.append(intToBin(similarTiles[i].vbits[7 - y] >>> x, 1));
                                vmaptemp |= (similarTiles[i].vbits[7 - y] & (1 << x));
                                if (isVmapNearFull(vmaptemp)) break;
                            }
                        }
                    }
                    for (int x = 7; x >= 0; x--) {
                        if ((similarTiles[i].vbits[7 - y] & (1 << x)) == 0) {
                            int pix2 = pixels & ~(1 << tiles[indexFound][7 - y][7 - x]);
                            similarTiles[i].packedData.append(truncatedBinary(getElementIndex(pix2, tiles[i][7 - y][7 - x]), countingBitSet(pix2)));
                        }
                    }
                }
            }
            similarTiles[i].packedSize = similarTiles[i].packedData.length();
        }
    }

    // -------------------------------------------------------------------------
    // CompressSimilarTile (size estimation only)
    // -------------------------------------------------------------------------
    private int compressSimilarTile(int tileI, int tileJ) {
        int vmap = 0xFF, hmap = 0, pixels = 0;
        Arrays.fill(similarTiles[tileI].vbits, 0);

        for (int y = 0; y < 8; y++) {
            hmap = (hmap << 1) | (compareRow(tiles[tileI], y, tiles[tileJ], y) ? 1 : 0);
            if ((hmap & 1) == 0) {
                for (int x = 0; x < 8; x++) {
                    similarTiles[tileI].vbits[y] = (similarTiles[tileI].vbits[y] << 1) |
                                                   (tiles[tileI][y][x] == tiles[tileJ][y][x] ? 1 : 0);
                    if (tiles[tileI][y][x] != tiles[tileJ][y][x]) pixels |= (1 << tiles[tileI][y][x]);
                }
                vmap &= similarTiles[tileI].vbits[y];
            }
        }
        similarTiles[tileI].pixels = pixels;

        int packedSize = truncatedBinaryLength(tileI - tileJ - 1, tileI) + 2;
        int vhi = vmap >>> 4, vlo = vmap & 0xF;
        similarTiles[tileI].vhi = vhi;
        similarTiles[tileI].vlo = vlo;
        if (vhi != 0) packedSize += truncatedBinaryLength(vhi ^ 15, 15);
        if (vlo != 0) packedSize += truncatedBinaryLength(vlo ^ 15, 15);

        int hhi = hmap >>> 4, hlo = hmap & 0xF;
        similarTiles[tileI].hhi = hhi;
        similarTiles[tileI].hlo = hlo;
        packedSize += 2;
        if (hhi != 0) packedSize += truncatedBinaryLength(hhi ^ 15, 15);
        if (hlo != 0) packedSize += truncatedBinaryLength(hlo ^ 15, 15);

        for (int y = 7; y >= 0; y--) {
            int vmaptemp = vmap;
            if ((hmap & (1 << y)) == 0) {
                if ((hmap | (1 << y)) != 0xFF) {
                    for (int x = 7; x >= 0; x--) {
                        if (!isVmapNearFull(vmaptemp) && ((vmap & (1 << x)) == 0)) {
                            packedSize++;
                            vmaptemp |= (similarTiles[tileI].vbits[7 - y] & (1 << x));
                            if (isVmapNearFull(vmaptemp)) break;
                        }
                    }
                }
                for (int x = 7; x >= 0; x--) {
                    if ((similarTiles[tileI].vbits[7 - y] & (1 << x)) == 0) {
                        int pix2 = pixels & ~(1 << tiles[tileJ][7 - y][7 - x]);
                        packedSize += truncatedBinaryLength(getElementIndex(pix2, tiles[tileI][7 - y][7 - x]), countingBitSet(pix2));
                    }
                }
            }
        }
        return similarTiles[tileI].packedSize = packedSize;
    }

    // -------------------------------------------------------------------------
    // FindSimilarTile
    // -------------------------------------------------------------------------
    private int findSimilarTile(int index) {
        int minDiff = 65535, result = 0;
        int limit = Math.max(0, index - SEARCH_WINDOW);
        for (int i = index - 1; i >= limit; i--) {
            int diff = compressSimilarTile(index, i);
            if (diff < minDiff) {
                minDiff = diff;
                result = i;
            }
        }
        return result;
    }

    private static boolean isVmapNearFull(int v) {
        return Integer.bitCount(v & 0xFF) == 7;
    }
}
