using Google.Apis.Auth.OAuth2;
using Google.Apis.Calendar.v3;
using Google.Apis.Calendar.v3.Data;
using Google.Apis.Services;

public class GoogleCalendarService
{
    private readonly CalendarService _calendarService;
    private readonly string _calendarId = "tu_correo_o_id_de_calendario@group.calendar.google.com"; // El ID de tu Google Calendar

    public GoogleCalendarService(IWebHostEnvironment env)
    {
        string credentialsPath = Path.Combine(env.ContentRootPath, "google-calendar-credentials.json");

        GoogleCredential credential;
        // Opción recomendada y más corta:
        using (var stream = File.OpenRead(credentialsPath))
        {
            credential = GoogleCredential.FromStream(stream)
                .CreateScoped(CalendarService.Scope.Calendar);
        }

        _calendarService = new CalendarService(new BaseClientService.Initializer()
        {
            HttpClientInitializer = credential,
            ApplicationName = "OrgEventos",
        });
    }

    public async Task<string> CrearEventoEnCalendarioAsync(string titulo, string descripcion, string ubicacion, DateTime fechaEvento)
    {
        var nuevoEvento = new Event()
        {
            Summary = $"[OrgEventos] {titulo}",
            Description = descripcion,
            Location = ubicacion,
            Start = new EventDateTime()
            {
                DateTimeDateTimeOffset = new DateTimeOffset(fechaEvento, TimeSpan.FromHours(-6)), // Ajusta tu zona horaria (ej. México Central)
                TimeZone = "America/Mexico_City",
            },
            End = new EventDateTime()
            {
                DateTimeDateTimeOffset = new DateTimeOffset(fechaEvento.AddHours(4), TimeSpan.FromHours(-6)), // Duración estimada de 4 horas
                TimeZone = "America/Mexico_City",
            },
        };

        var request = _calendarService.Events.Insert(nuevoEvento, _calendarId);
        var eventResponse = await request.ExecuteAsync();
        return eventResponse.Id; // Devuelve el ID del evento creado en Google
    }
}