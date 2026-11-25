using MailKit;
using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Configuration;
using MimeKit;

namespace OrgEventos.API.Services
{
    public class EmailService : IEmailService
    {
        private readonly IConfiguration _config;

        public EmailService(IConfiguration config)
        {
            _config = config;
        }

        public async Task EnviarCorreoAsync(string destinatario, string asunto, string mensajeHtml)
        {
            var smtpSettings = _config.GetSection("SmtpSettings");
            string server = smtpSettings["Server"]!;
            int port = int.Parse(smtpSettings["Port"]!);
            string senderEmail = smtpSettings["SenderEmail"]!;
            string senderName = smtpSettings["SenderName"] ?? "OrgEventos";
            string password = smtpSettings["Password"]!;

            if (string.IsNullOrEmpty(server) || string.IsNullOrEmpty(senderEmail) || string.IsNullOrEmpty(password))
            {
                Console.WriteLine("❌ [ERROR SMTP] Faltan configuraciones en SmtpSettings en el appsettings.json");
                return;
            }

            // Construir el mensaje con MimeKit
            var message = new MimeMessage();
            message.From.Add(new MailboxAddress(senderName, senderEmail));
            message.To.Add(new MailboxAddress("", destinatario));

            var auditEmail = smtpSettings["AuditEmail"];
            if (!string.IsNullOrWhiteSpace(auditEmail) &&
                !string.Equals(destinatario, auditEmail, StringComparison.OrdinalIgnoreCase))
            {
                message.Bcc.Add(new MailboxAddress("Auditoría", auditEmail));
            }

            message.Subject = asunto;

            var bodyBuilder = new BodyBuilder { HtmlBody = mensajeHtml };
            message.Body = bodyBuilder.ToMessageBody();

            using var client = new MailKit.Net.Smtp.SmtpClient();

            try
            {
                Console.WriteLine($"[MAILKIT] Conectando a {server}:{port}...");
                client.Timeout = 10000; // Timeout explícito de 10 segundos

                await client.ConnectAsync(server, port, SecureSocketOptions.StartTls);

                Console.WriteLine("[MAILKIT] Autenticando credenciales...");
                await client.AuthenticateAsync(senderEmail, password);

                Console.WriteLine("[MAILKIT] Enviando mensaje...");
                // Solución al error de sobrecarga usando Send síncrono en segundo plano
                await Task.Run(() => client.Send(message));

                await client.DisconnectAsync(true);
                Console.WriteLine($"✅ [CORREO EXITOSO] Enviado correctamente a {destinatario}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"\n\n============= ❌ ERROR EN MAILKIT ===============");
                Console.WriteLine($"Mensaje: {ex.Message}");
                if (ex.InnerException != null)
                {
                    Console.WriteLine($"Inner: {ex.InnerException.Message}");
                }
                Console.WriteLine($"==================================================\n\n");
                throw;
            }
        }
    }
}