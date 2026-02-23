public class TestLoopback {
    public static void main(String[] args) {
        try {
            var ss = new java.net.ServerSocket(0, 1, java.net.InetAddress.getByName("127.0.0.1"));
            System.out.println("Server socket opened on port: " + ss.getLocalPort());
            var s = new java.net.Socket("127.0.0.1", ss.getLocalPort());
            System.out.println("Connected! TCP loopback works.");
            s.close();
            ss.close();
        } catch (Exception e) {
            System.out.println("TCP loopback FAILED: " + e.getMessage());
            e.printStackTrace();
        }

        try {
            var pipe = java.nio.channels.Pipe.open();
            System.out.println("Pipe.open() works!");
            pipe.sink().close();
            pipe.source().close();
        } catch (Exception e) {
            System.out.println("Pipe.open() FAILED: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
