package sgdk.litepack;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;

public class Launcher
{
    /**
     * Launch the application.
     */
    public static void main(String[] args)
    {
        if (args.length < 2)
        {
            showUsage();
            System.exit(2);
        }

        final String cmd = args[0].toLowerCase();

        // invalid command
        if (!cmd.equals("p") && !cmd.equals("u"))
        {
            showUsage();
            System.exit(2);
        }

        String inputFile = args[1];
        String prevFile = "";

        final int sep = inputFile.indexOf('@');
        // file separator character found ?
        if (sep != -1)
        {
            prevFile = inputFile.substring(0, sep);
            inputFile = inputFile.substring(sep + 1, inputFile.length());
        }

        final String outputFile;
        boolean silent;

        if (args.length > 2)
            outputFile = args[2];
        else
        {
            if (cmd.equals("p"))
                outputFile = "packed.dat";
            else
                outputFile = "unpacked.dat";
        }

        // assume the fourth argument as silent
        silent = (args.length > 3);

        if (execute(cmd, prevFile, inputFile, outputFile, silent))
            System.exit(0);
        else
            System.exit(1);
    }

    static boolean execute(String cmd, String prevFile, String inputFile, String outputFile, boolean silent)
    {
		silent = false;
        try
        {
            final byte[] data1 = pad((prevFile.isEmpty() ? new byte[0] : readBinaryFile(prevFile)));
            final byte[] data2 = readBinaryFile(inputFile);
            final byte[] data = new byte[data1.length + data2.length];
            byte[] result;

            // concatenate the 2 arrays
            System.arraycopy(data1, 0, data, 0, data1.length);
            System.arraycopy(data2, 0, data, data1.length, data2.length);

            final long start = System.currentTimeMillis();

            // compress
            if (cmd.equals("p"))
            {
                if (!silent)
                    System.out.println("Packing " + inputFile + "...");

                try
                {
                    result = LITEPACK.pack(data, data1.length, silent);
                }
                catch (IllegalArgumentException e1)
                {
                    // try to pack without previous data block then
                    result = LITEPACK.pack(data2, 0, silent);
                }

                // get elapsed time
                final long time = System.currentTimeMillis() - start;
                final byte[] resultFull = new byte[data1.length + result.length];

                // concatenate the 2 arrays
                System.arraycopy(data1, 0, resultFull, 0, data1.length);
                System.arraycopy(result, 0, resultFull, data1.length, result.length);

                // verify compression
                final byte[] unpacked = LITEPACK.unpack(resultFull, data1.length, data, silent);

                if (!silent)
                {
                    System.out.println("Initial size " + data2.length + " --> packed to " + result.length + " ("
                            + ((100 * result.length) / data2.length) + "%) in " + time + " ms");
                }

                if (!Arrays.equals(data2, unpacked))
                {
                    System.err.println("Error while verifying compression, result data mismatch input data !");
                    return false;
                }
            }
            // unpack
            else
            {
                if (!silent)
                    System.out.println("Unpacking " + inputFile + "...");

                result = LITEPACK.unpack(data, data1.length, null, silent);

                final long time = System.currentTimeMillis() - start;
                if (!silent)
                {
                    System.out.println("Initial size " + data2.length + " --> unpacked to " + result.length + " in "
                            + time + " ms");
                }
            }

            writeBinaryFile(result, outputFile);
        }
        catch (IOException e)
        {
            System.out.println(e);
            return false;
        }

        return true;
    }

    /**
     * Align size to word
     */
    static byte[] pad(byte[] buffer)
    {
        // need to pad ?
        if ((buffer.length & 1) == 1)
        {
            final byte[] result = new byte[buffer.length + 1];
            System.arraycopy(buffer, 0, result, 0, buffer.length);
            return result;
        }

        return buffer;
    }

    static void showUsage()
    {
        System.out.println("LITEPACK packer v1 by Revengenesis (Copyright 2026)");
        System.out.println("  Pack:     java -jar litepack.jar p <input_file> <output_file>");
        System.out.println("            java -jar litepack.jar p <prev_file>&<input_file> <output_file>");
        System.out.println("  Unpack:   java -jar litepack.jar u <input_file> <output_file>");
        System.out.println("            java -jar litepack.jar u <prev_file>&<input_file> <output_file>");
        System.out.println();
        System.out.println("Tip: using an extra parameter after <output_file> will act as 'silent mode' switch");
    }

    public static byte[] readBinaryFile(String fileName) throws IOException
    {
        Path path = Paths.get(fileName);
        return Files.readAllBytes(path);
    }

    public static void writeBinaryFile(byte[] data, String fileName) throws IOException
    {
        Path path = Paths.get(fileName);
        Files.write(path, data);
    }
}
