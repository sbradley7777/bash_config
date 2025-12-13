import java.io.*;
import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.io.RandomAccessFile;
import java.nio.channels.FileChannel;
import java.nio.channels.FileLock;

import java.net.*;
import java.sql.Timestamp;
import java.util.Date;

public class LockTest {
    private static void logmsg(String commandline) {
        try {
            String line;
            Process p = Runtime.getRuntime().exec(commandline);
            BufferedReader input =
                new BufferedReader
                (new InputStreamReader(p.getInputStream()));
            while ((line = input.readLine()) != null) {
                System.out.println(line);
            }
            input.close();
        } catch (Exception err) {
            err.printStackTrace();
        }
    }

    private static String getTimestamp() {
        java.util.Date date= new java.util.Date();
        return new Timestamp(date.getTime()).toString();
    }

    private static void writeString(RandomAccessFile raf, String data) {
        try {
            raf.writeChars(data);
        } catch (IOException e) {
            System.err.println(getTimestamp() + ": ERROR: Exception=" + e.toString());
        }
    }

    public static void main(String[] argv) {
		try {
            String hostname = InetAddress.getLocalHost().getHostName();
            logmsg("/bin/logger -t LockTest Executing LockTest.java");
			BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
			File f = new File(argv[0]);
			RandomAccessFile raf = new RandomAccessFile(f, "rw");
			FileChannel fc = raf.getChannel();

			System.out.print(getTimestamp() + ": INFO: Press the <Enter> key to lock the file ");
			System.out.flush();
			String inLine = br.readLine();
			for ( ; ; ) {
				System.out.println(getTimestamp() + ": INFO: About to lock ... ");
				System.out.flush();
				FileLock fl = fc.lock();
				if (fl == null) {
                    logmsg("/bin/logger -t LockTest The file is NOT locked: " + argv[0]);
					System.err.println(getTimestamp() + ": ERROR: Not locked!");
					System.exit(1);
				}
                String currentTimestamp = getTimestamp();
                writeString(raf, currentTimestamp + ": " + hostname + " has locked the file.\n");
                logmsg("/bin/logger -t LockTest The file is LOCKED: " + argv[0]);
				System.out.print(currentTimestamp + ": INFO: Locked!  Press the <Enter> key to release the file lock ");
				System.out.flush();
				inLine = br.readLine();

                currentTimestamp = getTimestamp();
				System.out.println(currentTimestamp + ": INFO: About to release ... ");
				System.out.flush();

                writeString(raf, currentTimestamp + ": " + hostname + " is releasing the file.\n");
				fl.release();
                logmsg("/bin/logger -t LockTest The file is unlocked: " + argv[0]);

				System.out.print(currentTimestamp + ": INFO: Released! Press the <Enter> key to lock the file ");
				System.out.flush();
				inLine = br.readLine();
			}
		} catch (Exception e) {
			System.err.println(getTimestamp() + ": ERROR: Exception=" + e.toString());
			System.exit(1);
		}
		System.exit(0);
	}
}

