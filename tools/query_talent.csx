using Microsoft.Data.Sqlite;
using System.Text;

const byte XorKey = 0x55;
var path = @"E:\逆向工程\苍蓝誓约项目\blueoath\blueoath\blueoath_Data\StreamingAssets\config\config_talent.db";
var builder = new SqliteConnectionStringBuilder { DataSource = path, Mode = SqliteOpenMode.ReadOnly, Pooling = false };
using var conn = new SqliteConnection(builder.ConnectionString);
conn.Open();
using var cmd = conn.CreateCommand();
cmd.CommandText = "SELECT id, indexid, jsonbytes FROM DBObject LIMIT 5";
using var reader = cmd.ExecuteReader();
while (reader.Read()) {
    var id = reader.IsDBNull(0) ? "NULL" : Convert.ToString(reader.GetValue(0));
    var idx = reader.IsDBNull(1) ? "NULL" : Convert.ToString(reader.GetValue(1));
    var raw = new byte[0];
    var val = reader.GetValue(2);
    if (val is byte[] b) raw = b;
    else if (val is string s) raw = Encoding.UTF8.GetBytes(s);
    var decoded = new byte[raw.Length];
    for (int i = 0; i < raw.Length; i++) decoded[i] = (byte)(raw[i] ^ XorKey);
    var json = Encoding.UTF8.GetString(decoded);
    Console.WriteLine($"id={id} idx={idx} json={json[..Math.Min(200, json.Length)]}");
}
