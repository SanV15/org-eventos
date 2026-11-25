using Amazon;
using Amazon.S3;
using Amazon.S3.Model;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace OrgEventos.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class AudioController : ControllerBase
    {
        private readonly IConfiguration _config;

        public AudioController(IConfiguration config)
        {
            _config = config;
        }

        [HttpGet("presigned-url")]
        public IActionResult ObtenerUrlSubida([FromQuery] string extension = "m4a")
        {
            try
            {
                string bucketname = _config["AWS:BucketName"];
                string accessKey = _config["AWS:AccessKey"];
                string secretKey = _config["AWS:SecretKey"];
                var region = RegionEndpoint.GetBySystemName(_config["AWS:Region"] ?? "us-west-2");

                var s3Client = new AmazonS3Client(accessKey, secretKey, region);

                //Nombre único para el audio en la carpeta audios/
                string objectKey = $"audios/{Guid.NewGuid()}.{extension}";

                //URL temporal para que el cliente haga PUT (válida por 5 minutos)
                var requestSubida = new GetPreSignedUrlRequest
                {
                    BucketName = bucketname,
                    Key = objectKey,
                    Verb = HttpVerb.PUT,
                    Expires = DateTime.UtcNow.AddMinutes(5),
                    ContentType = "audio/m4a"
                };

                //URL Para que los demás escuchen el audio (válida por 4 horas)
                var requestDescarga = new GetPreSignedUrlRequest
                {
                    BucketName = bucketname,
                    Key = objectKey,
                    Verb = HttpVerb.GET,
                    Expires = DateTime.UtcNow.AddHours(12)
                };

                string uploadUrl = s3Client.GetPreSignedURL(requestSubida);
                string publicUrl = s3Client.GetPreSignedURL(requestDescarga);

                return Ok(new { uploadUrl, publicUrl, fileName = objectKey });

            } catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = " Error al generar la URL prefirmada para la subida del audio.", detalle = ex.Message });
            }
        }
    }
}
