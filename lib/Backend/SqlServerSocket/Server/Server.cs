using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using Newtonsoft.Json;
using SimpleDB;

public class Server
{
    // Thread signal.
    public static ManualResetEvent allDone = new ManualResetEvent(false);
    private int port;
    // Connection counter to assign unique IDs to each connection
    private static int connectionCounter = 0;

    public Server(int port)
    {
        this.port = port;
    }

    public void StartListening()
    {
        // Bind to all network interfaces.
        IPEndPoint localEndPoint = new IPEndPoint(IPAddress.Any, port);
        Console.WriteLine($"SocketSQL is listening on port {port} ... press ^C to exit");

        // Create a TCP/IP socket.
        Socket listener = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);

        try
        {
            listener.Bind(localEndPoint);
            listener.Listen(100);

            while (true)
            {
                // Set the event to nonsignaled state.
                allDone.Reset();

                listener.BeginAccept(new AsyncCallback(AcceptCallback), listener);

                // Wait until a connection is made before continuing.
                allDone.WaitOne(1000);

                if (Program.exitFlag)
                    return;
            }
        }
        catch (Exception e)
        {
            Console.WriteLine(e.ToString());
        }
    }

    public void AcceptCallback(IAsyncResult ar)
    {
        // Signal the main thread to continue.
        allDone.Set();

        // Get the socket that handles the client request.
        Socket listener = (Socket)ar.AsyncState;
        Socket handler = listener.EndAccept(ar);

        // Create the state object.
        StateObject state = new StateObject();
        state.workSocket = handler;
        // Assign a unique connection ID (thread-safe)
        state.ConnectionId = Interlocked.Increment(ref connectionCounter);
        Console.WriteLine($"Connection {state.ConnectionId} established.");

        handler.BeginReceive(state.buffer, 0, StateObject.BufferSize, 0, new AsyncCallback(ReadCallback), state);
    }

    public void ReadCallback(IAsyncResult ar)
    {
        string content = string.Empty;

        // Retrieve the state object and the handler socket.
        StateObject state = (StateObject)ar.AsyncState;
        Socket handler = state.workSocket;

        int bytesRead = 0;
        try
        {
            bytesRead = handler.EndReceive(ar);
        }
        catch (SocketException)
        {
            Console.WriteLine($"Connection {state.ConnectionId} forced disconnect.");
            handler.Shutdown(SocketShutdown.Both);
            handler.Close();
            return;
        }

        if (bytesRead > 0)
        {
            // Append the data received so far.
            state.sb.Append(Encoding.UTF8.GetString(state.buffer, 0, bytesRead));
            content = state.sb.ToString();

            // Check for the end-of-file marker (\r\n).
            if (content.IndexOf("\r\n") > -1)
            {
                int x = content.IndexOf("\r\n");
                int len = int.Parse(content.Substring(0, x));
                string cmd = content.Substring(x + 2);
                if (cmd.Length == len)
                {
                    // All data has been read from the client.
                    string result = ParseCommand(cmd, state);
                    state.sb = new StringBuilder();

                    // Echo the data back to the client.
                    Send(handler, result);

                    // Check if client requested disconnect.
                    if (state.disconnect)
                    {
                        Console.WriteLine($"Connection {state.ConnectionId} closed on request.");
                        handler.Shutdown(SocketShutdown.Both);
                        handler.Close();
                        return;
                    }
                }
            }
        }

        // Continue receiving data.
        handler.BeginReceive(state.buffer, 0, StateObject.BufferSize, 0, new AsyncCallback(ReadCallback), state);
    }

    private void Send(Socket handler, string data)
    {
        // Prepend the length and marker.
        string dataToSend = data.Length.ToString() + "\r\n" + data;
        byte[] byteData = Encoding.UTF8.GetBytes(dataToSend);

        handler.BeginSend(byteData, 0, byteData.Length, 0, new AsyncCallback(SendCallback), handler);
    }

    private void SendCallback(IAsyncResult ar)
    {
        try
        {
            Socket handler = (Socket)ar.AsyncState;
            if (handler == null)
            {
                Console.WriteLine("handler is null");
                return;
            }
            int bytesSent = handler.EndSend(ar);
        }
        catch (Exception)
        {
            // Optionally log errors.
        }
    }

    public string ParseCommand(string command, StateObject st)
    {
        object ob = ParseCommandInner(command, st);
        return JsonConvert.SerializeObject(ob);
    }

    public object ParseCommandInner(string command, StateObject st)
    {
        Command cmd;
        try
        {
            cmd = JsonConvert.DeserializeObject<Command>(command);
        }
        catch (Exception)
        {
            return new ErrorResult("invalid command");
        }

        if (cmd.type == "open")
        {
            if (st.database.Connected)
                return new ErrorResult("already connected");
            try
            {
                st.database.connectionString = cmd.text;
                st.database.Open();
                return new OkResult();
            }
            catch (Exception ex)
            {
                return new ErrorResult(ex.Message);
            }
        }
        else if (cmd.type == "close")
        {
            if (!st.database.Connected)
                return new ErrorResult("not connected");
            st.database.Close();
            st.disconnect = true;
            return new OkResult();
        }
        else if (cmd.type == "table")
        {
            if (!st.database.Connected)
                return new ErrorResult("not connected");
            try
            {
                var table = st.database.QueryTable(cmd.text);
                return new TableResult(table);
            }
            catch (Exception ex)
            {
                return new ErrorResult(ex.Message);
            }
        }
        else if (cmd.type == "postback")
        {
            if (!st.database.Connected)
                return new ErrorResult("not connected");
            ChangeSet changes;
            try
            {
                changes = JsonConvert.DeserializeObject<ChangeSet>(cmd.text);
            }
            catch (Exception)
            {
                return new ErrorResult("invalid postback command");
            }
            try
            {
                var response = PostBackManager.DoPostBack(st.database, changes);
                return new PostBackResult(response.idcolumn, response.identities);
            }
            catch (Exception ex)
            {
                return new ErrorResult(ex.Message);
            }
        }
        else if (cmd.type == "query")
        {
            if (!st.database.Connected)
                return new ErrorResult("not connected");
            try
            {
                var query = st.database.Query(cmd.text);
                return new DataResult(query);
            }
            catch (Exception ex)
            {
                return new ErrorResult(ex.Message);
            }
        }
        else if (cmd.type == "querysingle")
        {
            if (!st.database.Connected)
                return new ErrorResult("not connected");
            try
            {
                var query = st.database.QuerySingle(cmd.text);
                return new DataResult(query);
            }
            catch (Exception ex)
            {
                return new ErrorResult(ex.Message);
            }
        }
        else if (cmd.type == "queryvalue")
        {
            if (!st.database.Connected)
                return new ErrorResult("not connected");
            try
            {
                var query = st.database.QueryValue(cmd.text);
                return new DataResult(query);
            }
            catch (Exception ex)
            {
                return new ErrorResult(ex.Message);
            }
        }
        else if (cmd.type == "execute")
        {
            if (!st.database.Connected)
                return new ErrorResult("not connected");
            try
            {
                var query = st.database.Execute(cmd.text);
                return new DataResult(query);
            }
            catch (Exception ex)
            {
                return new ErrorResult(ex.Message);
            }
        }
        else
        {
            return new ErrorResult("unknown command");
        }
    }
}

// Result and command classes.
public class OkResult
{
    public string type;
    public OkResult()
    {
        type = "ok";
    }
}

public class ErrorResult
{
    public string type;
    public string error;
    public ErrorResult(string message)
    {
        type = "error";
        error = message;
        Console.WriteLine(message);
    }
}

public class DataResult
{
    public string type;
    public List<Row> rows;
    public Dictionary<string, string> columns;
    public DataResult(QueryResult data)
    {
        type = "query";
        rows = data.rows;
        columns = data.columns;
    }
}

public class TableResult
{
    public string type;
    public List<Row> rows;
    public string tablename;
    public ColumnDefinitions columns;
    public TableResult(QueryTableResult data)
    {
        type = "table";
        rows = data.rows;
        tablename = data.TableName;
        columns = data.columns;
    }
}

public class PostBackResult
{
    public string type;
    public string idcolumn;
    public List<int> identities;
    public PostBackResult(string idcolumn, List<int> identities)
    {
        type = "postback";
        this.idcolumn = idcolumn;
        this.identities = identities;
    }
}

public class Command
{
    public string type;
    public string text;
}
