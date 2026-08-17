using System.Net;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;

namespace BlueOath.Server.Infrastructure;

/// <summary>
/// 本地开发用的自签名 TLS 证书：生成一个根证书与一个叶子服务器证书（含多个 SAN），
/// 并把它们导出为 .cer/.pfx/.pem 文件供启动脚本和 OpenSSL 代理使用。
/// </summary>
internal sealed class DevelopmentTlsMaterial : IDisposable
{
    private DevelopmentTlsMaterial(X509Certificate2 serverCertificate, X509Certificate2 rootCertificate,
        string rootCertificatePath, string leafCertificatePath, string leafPemPath, string leafKeyPemPath)
    {
        ServerCertificate = serverCertificate;
        RootCertificate = rootCertificate;
        RootCertificatePath = rootCertificatePath;
        LeafCertificatePath = leafCertificatePath;
        LeafPemPath = leafPemPath;
        LeafKeyPemPath = leafKeyPemPath;
    }

    public X509Certificate2 ServerCertificate { get; }
    public X509Certificate2 RootCertificate { get; }
    public string RootCertificatePath { get; }
    public string LeafCertificatePath { get; }
    public string LeafPemPath { get; }
    public string LeafKeyPemPath { get; }

    public static DevelopmentTlsMaterial Create(string outputDirectory)
    {
        Directory.CreateDirectory(outputDirectory);

        // 根证书（自签名，用于签发叶子证书）。
        var rootKey = RSA.Create(2048);
        var rootRequest = new CertificateRequest(
            "CN=BlueOath Local Development Root",
            rootKey,
            HashAlgorithmName.SHA256,
            RSASignaturePadding.Pkcs1);
        rootRequest.CertificateExtensions.Add(new X509BasicConstraintsExtension(true, false, 0, true));
        rootRequest.CertificateExtensions.Add(new X509KeyUsageExtension(
            X509KeyUsageFlags.KeyCertSign | X509KeyUsageFlags.CrlSign,
            true));
        rootRequest.CertificateExtensions.Add(new X509SubjectKeyIdentifierExtension(rootRequest.PublicKey, false));
        var now = DateTimeOffset.UtcNow;
        var rootCertificate = rootRequest.CreateSelfSigned(
            now.AddMinutes(-5),
            now.AddDays(7));

        // 叶子服务器证书，SAN 覆盖真实客户端会访问到的域名与本机回环地址。
        var leafKey = RSA.Create(2048);
        var leafRequest = new CertificateRequest(
            "CN=mapijpshipgirl.blueoath.com",
            leafKey,
            HashAlgorithmName.SHA256,
            RSASignaturePadding.Pkcs1);
        leafRequest.CertificateExtensions.Add(new X509BasicConstraintsExtension(false, false, 0, true));
        leafRequest.CertificateExtensions.Add(new X509KeyUsageExtension(
            X509KeyUsageFlags.DigitalSignature | X509KeyUsageFlags.KeyEncipherment,
            true));
        var enhancedKeyUsage = new OidCollection { new("1.3.6.1.5.5.7.3.1") };
        leafRequest.CertificateExtensions.Add(new X509EnhancedKeyUsageExtension(enhancedKeyUsage, true));
        var subjectAlternativeNames = new SubjectAlternativeNameBuilder();
        subjectAlternativeNames.AddDnsName("mapijpshipgirl.blueoath.com");
        subjectAlternativeNames.AddDnsName("haina.blueoath.com");
        subjectAlternativeNames.AddDnsName("localhost");
        subjectAlternativeNames.AddIpAddress(IPAddress.Loopback);
        leafRequest.CertificateExtensions.Add(subjectAlternativeNames.Build());
        leafRequest.CertificateExtensions.Add(new X509SubjectKeyIdentifierExtension(leafRequest.PublicKey, false));

        var serial = RandomNumberGenerator.GetBytes(16);
        using var unsignedLeaf = leafRequest.Create(
            rootCertificate,
            now.AddMinutes(-5),
            now.AddDays(7).AddMinutes(-1),
            serial);
        var serverCertificate = unsignedLeaf.CopyWithPrivateKey(leafKey);

        // 导出多种格式：根证书 .cer、叶子证书 .pfx 以及给 OpenSSL 代理的 .pem/.key。
        var rootCertificatePath = Path.Combine(outputDirectory, "blueoath-local-root.cer");
        var leafCertificatePath = Path.Combine(outputDirectory, "blueoath-local-leaf.pfx");
        var leafPemPath = Path.Combine(outputDirectory, "blueoath-local-leaf.pem");
        var leafKeyPemPath = Path.Combine(outputDirectory, "blueoath-local-leaf-key.pem");
        File.WriteAllBytes(rootCertificatePath, rootCertificate.Export(X509ContentType.Cert));
        const string pfxPassword = "blueoath-local";
        var pfxBytes = serverCertificate.Export(X509ContentType.Pfx, pfxPassword);
        File.WriteAllBytes(leafCertificatePath, pfxBytes);
        File.WriteAllText(leafPemPath, serverCertificate.ExportCertificatePem());
        File.WriteAllText(leafKeyPemPath, leafKey.ExportPkcs8PrivateKeyPem());

        rootKey.Dispose();
        leafKey.Dispose();
        return new DevelopmentTlsMaterial(serverCertificate, rootCertificate,
            rootCertificatePath, leafCertificatePath, leafPemPath, leafKeyPemPath);
    }

    public void Dispose()
    {
        ServerCertificate.Dispose();
        RootCertificate.Dispose();
    }
}
