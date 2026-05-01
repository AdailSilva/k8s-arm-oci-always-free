//package Main;

import java.net.DatagramPacket;
import java.net.DatagramSocket;

public class UdpHealthCheckServer {
	public static void main(String[] args) {

		if (args.length < 1) {
			System.err.println("Enter the port as a parameter: java UdpHealthCheckServer <port>");
			System.exit(1);
		}

		final int port;
		try {
			port = Integer.parseInt(args[0]);
		} catch (NumberFormatException e) {
			System.err.println("Invalid port: " + args[0]);
			return;
		}

		final String expectedRequest = "PING";
		final String response = "PONG";

		try (final DatagramSocket socket = new DatagramSocket(port)) {
			System.out.println("UDP health check server is listening on port " + port);

			final byte[] receiveBuffer = new byte[1024];

			while (true) {
				final DatagramPacket requestPacket = new DatagramPacket(receiveBuffer, receiveBuffer.length);
				socket.receive(requestPacket);

				final String receivedData = new String(requestPacket.getData(), 0, requestPacket.getLength());

				if (receivedData.trim().startsWith(expectedRequest)) {
					final byte[] sendBuffer = response.getBytes();
					final DatagramPacket responsePacket = new DatagramPacket(sendBuffer, sendBuffer.length,
							requestPacket.getAddress(), requestPacket.getPort());
					socket.send(responsePacket);
					System.out.println("Responded with PONG to " + requestPacket.getAddress());
				} else {
					System.out.println("Received unexpected data: " + receivedData);
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}
