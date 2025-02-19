using System;
using System.Net.Sockets;
using System.Text;
using SimpleDB;

// State object for reading client data asynchronously
public class StateObject 
{    
    public Socket workSocket = null;               // Client socket    
    public const int BufferSize = 1024;             // Size of receive buffer    
    public byte[] buffer = new byte[BufferSize];      // Receive buffer    
    public StringBuilder sb = new StringBuilder();    // Received data string    
    public Database database = new Database();        // Database connection    
    public bool disconnect = false;                   // Disconnect flag

    // Unique connection identifier
    public int ConnectionId { get; set; }
}
