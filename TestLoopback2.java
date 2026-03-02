public class TestLoopback2 {
    public static void main(String[] args) {
        System.out.println("java.io.tmpdir = " + System.getProperty("java.io.tmpdir"));
        System.out.println("jdk.net.unixdomain.tmpdir = " + System.getProperty("jdk.net.unixdomain.tmpdir"));
        System.out.println("os.name = " + System.getProperty("os.name"));
        System.out.println("os.version = " + System.getProperty("os.version"));

        // Test Unix domain socket directly
        try {
            var addr = java.net.UnixDomainSocketAddress.of(
                System.getProperty("java.io.tmpdir") + "/test_uds.sock");
            var ssc = java.nio.channels.ServerSocketChannel.open(java.net.StandardProtocolFamily.UNIX);
            ssc.bind(addr);
            System.out.println("Unix domain server socket bound OK at: " + addr);
            var sc = java.nio.channels.SocketChannel.open(java.net.StandardProtocolFamily.UNIX);
            sc.connect(addr);
            System.out.println("Unix domain socket connected OK!");
            sc.close();
            ssc.close();
            new java.io.File(addr.getPath().toString()).delete();
        } catch (Exception e) {
            System.out.println("Unix domain socket FAILED: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
