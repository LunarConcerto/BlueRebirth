using System.Text.Json.Serialization;

namespace BlueOath.Server.Protocols;

internal sealed class AnnouncementConfig
{
    [JsonPropertyName("maintainNotices")]
    public List<AnnouncementItem> MaintainNotices { get; set; } = [];

    [JsonPropertyName("noticeBoard")]
    public NoticeBoardConfig? NoticeBoard { get; set; }

    [JsonPropertyName("innerBrowse")]
    public List<AnnouncementItem> InnerBrowse { get; set; } = [];
}

internal sealed class AnnouncementItem
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = "";

    [JsonPropertyName("begin_time")]
    public long BeginTime { get; set; }

    [JsonPropertyName("end_time")]
    public long EndTime { get; set; }
}

internal sealed class NoticeBoardConfig
{
    [JsonPropertyName("beforgame")]
    public NoticeBoardItem? Beforgame { get; set; }

    [JsonPropertyName("ingame")]
    public NoticeBoardItem? Ingame { get; set; }
}

internal sealed class NoticeBoardItem
{
    [JsonPropertyName("status")]
    public int Status { get; set; }

    [JsonPropertyName("begintime")]
    public long BeginTime { get; set; }

    [JsonPropertyName("endtime")]
    public long EndTime { get; set; }
}