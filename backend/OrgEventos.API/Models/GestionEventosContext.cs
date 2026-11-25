using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace OrgEventos.API.Models;

public partial class GestionEventosContext : DbContext
{
    public GestionEventosContext()
    {
    }

    public GestionEventosContext(DbContextOptions<GestionEventosContext> options)
        : base(options)
    {
    }

    public virtual DbSet<CategoriaProveedor> CategoriaProveedors { get; set; }

    public virtual DbSet<Cliente> Clientes { get; set; }

    public virtual DbSet<Contrato> Contratos { get; set; }

    public virtual DbSet<Cotizacion> Cotizacions { get; set; }

    public virtual DbSet<CotizacionDetalle> CotizacionDetalles { get; set; }

    public virtual DbSet<CotizacionProveedor> CotizacionProveedors { get; set; }

    public virtual DbSet<Cuotum> Cuota { get; set; }

    public virtual DbSet<Evento> Eventos { get; set; }

    public virtual DbSet<EventoProveedor> EventoProveedors { get; set; }

    public virtual DbSet<IncidenciaTarea> IncidenciaTareas { get; set; }

    public virtual DbSet<PagoCliente> PagoClientes { get; set; }

    public virtual DbSet<PagoProveedor> PagoProveedors { get; set; }

    public virtual DbSet<PlanPago> PlanPagos { get; set; }

    public virtual DbSet<Proveedor> Proveedors { get; set; }

    public virtual DbSet<ProveedorCategorium> ProveedorCategoria { get; set; }

    public virtual DbSet<Rol> Rols { get; set; }

    public virtual DbSet<Servicio> Servicios { get; set; }

    public virtual DbSet<ServicioProveedor> ServicioProveedors { get; set; }

    public virtual DbSet<Tarea> Tareas { get; set; }

    public virtual DbSet<TipoEvento> TipoEventos { get; set; }

    public virtual DbSet<Usuario> Usuarios { get; set; }
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<CategoriaProveedor>(entity =>
        {
            entity.HasKey(e => e.IdCategoria);

            entity.ToTable("CATEGORIA_PROVEEDOR", tb => tb.HasComment("Contiene las categorías utilizadas para clasificar a los proveedores."));

            entity.HasIndex(e => e.Nombre, "UQ_CATEGORIA_PROVEEDOR_NOMBRE").IsUnique();

            entity.Property(e => e.IdCategoria).HasColumnName("id_categoria");
            entity.Property(e => e.Descripcion)
                .HasMaxLength(500)
                .IsUnicode(false)
                .HasColumnName("descripcion");
            entity.Property(e => e.Nombre)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("nombre");
        });

        modelBuilder.Entity<Cliente>(entity =>
        {
            entity.HasKey(e => e.IdCliente);

            entity.ToTable("CLIENTE", tb => tb.HasComment("Almacena la información de los clientes de la empresa y su relación con una cuenta de usuario."));

            entity.HasIndex(e => e.IdUsuario, "UQ_CLIENTE_USUARIO").IsUnique();

            entity.Property(e => e.IdCliente).HasColumnName("id_cliente");
            entity.Property(e => e.Activo)
                .HasDefaultValue(true)
                .HasColumnName("activo");
            entity.Property(e => e.ApellidoMaterno)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("apellido_materno");
            entity.Property(e => e.ApellidoPaterno)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("apellido_paterno");
            entity.Property(e => e.Correo)
                .HasMaxLength(150)
                .IsUnicode(false)
                .HasColumnName("correo");
            entity.Property(e => e.Direccion)
                .HasMaxLength(250)
                .IsUnicode(false)
                .HasColumnName("direccion");
            entity.Property(e => e.FechaRegistro)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("fecha_registro");
            entity.Property(e => e.IdUsuario).HasColumnName("id_usuario");
            entity.Property(e => e.Nombre)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("nombre");
            entity.Property(e => e.StripeCustomerId)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("stripe_customer_id");
            entity.Property(e => e.Telefono)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("telefono");

            entity.HasOne(d => d.IdUsuarioNavigation).WithOne(p => p.Cliente)
                .HasForeignKey<Cliente>(d => d.IdUsuario)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CLIENTE_USUARIO");
        });

        modelBuilder.Entity<Contrato>(entity =>
        {
            entity.HasKey(e => e.IdContrato).HasName("PK__CONTRATO__FF5F2A56CC011ED0");

            entity.ToTable("CONTRATO");

            entity.HasIndex(e => e.IdEvento, "UQ__CONTRATO__AF150CA439993275").IsUnique();

            entity.Property(e => e.IdContrato).HasColumnName("id_contrato");
            entity.Property(e => e.Estado)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("estado");
            entity.Property(e => e.FechaContrato)
                .HasColumnType("datetime")
                .HasColumnName("fecha_contrato");
            entity.Property(e => e.IdEvento).HasColumnName("id_evento");
            entity.Property(e => e.MontoAcordado)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("monto_acordado");

            entity.HasOne(d => d.IdEventoNavigation).WithOne(p => p.Contrato)
                .HasForeignKey<Contrato>(d => d.IdEvento)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Contrato_Evento");
        });

        modelBuilder.Entity<Cotizacion>(entity =>
        {
            entity.HasKey(e => e.IdCotizacion);

            entity.ToTable("COTIZACION", tb => tb.HasComment("Almacena las cotizaciones generadas para los clientes."));

            entity.Property(e => e.IdCotizacion).HasColumnName("id_cotizacion");
            entity.Property(e => e.Estado)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasDefaultValue("Pendiente")
                .HasColumnName("estado");
            entity.Property(e => e.Fecha)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("fecha");
            entity.Property(e => e.FechaReferencia).HasColumnName("fecha_referencia");
            entity.Property(e => e.IdCliente).HasColumnName("id_cliente");
            entity.Property(e => e.Total)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("total");

            entity.HasOne(d => d.IdClienteNavigation).WithMany(p => p.Cotizacions)
                .HasForeignKey(d => d.IdCliente)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_COTIZACION_CLIENTE");
        });

        modelBuilder.Entity<CotizacionDetalle>(entity =>
        {
            entity.HasKey(e => e.IdDetalle);

            entity.ToTable("COTIZACION_DETALLE", tb => tb.HasComment("Detalla los servicios incluidos en cada cotización, incluyendo cantidad y precio utilizado al momento de cotizar."));

            entity.Property(e => e.IdDetalle).HasColumnName("id_detalle");
            entity.Property(e => e.Cantidad).HasColumnName("cantidad");
            entity.Property(e => e.IdCotizacion).HasColumnName("id_cotizacion");
            entity.Property(e => e.IdServicio).HasColumnName("id_servicio");
            entity.Property(e => e.PrecioUnitario)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("precio_unitario");

            entity.HasOne(d => d.IdCotizacionNavigation).WithMany(p => p.CotizacionDetalles)
                .HasForeignKey(d => d.IdCotizacion)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_COTIZACION_DETALLE_COTIZACION");

            entity.HasOne(d => d.IdServicioNavigation).WithMany(p => p.CotizacionDetalles)
                .HasForeignKey(d => d.IdServicio)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_COTIZACION_DETALLE_SERVICIO");
        });

        modelBuilder.Entity<CotizacionProveedor>(entity =>
        {
            entity.HasKey(e => e.IdCotizacionProveedor).HasName("PK__COTIZACI__D282335493475E04");

            entity.ToTable("COTIZACION_PROVEEDOR");

            entity.Property(e => e.IdCotizacionProveedor).HasColumnName("id_cotizacion_proveedor");
            entity.Property(e => e.Cantidad).HasColumnName("cantidad");
            entity.Property(e => e.IdCotizacion).HasColumnName("id_cotizacion");
            entity.Property(e => e.IdServicioProveedor).HasColumnName("id_servicio_proveedor");
            entity.Property(e => e.Observaciones)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("observaciones");
            entity.Property(e => e.PrecioCotizado)
                .HasColumnType("decimal(18, 2)")
                .HasColumnName("precio_cotizado");

            entity.HasOne(d => d.IdCotizacionNavigation).WithMany(p => p.CotizacionProveedors)
                .HasForeignKey(d => d.IdCotizacion)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CotizacionProveedor_Cotizacion");

            entity.HasOne(d => d.IdServicioProveedorNavigation).WithMany(p => p.CotizacionProveedors)
                .HasForeignKey(d => d.IdServicioProveedor)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CotizacionProveedor_ServicioProveedor");
        });

        modelBuilder.Entity<Cuotum>(entity =>
        {
            entity.HasKey(e => e.IdCuota).HasName("PK__CUOTA__5EFF6F7EB5FFF36C");

            entity.ToTable("CUOTA");

            entity.Property(e => e.IdCuota).HasColumnName("id_cuota");
            entity.Property(e => e.Estado)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("estado");
            entity.Property(e => e.FechaLimite).HasColumnName("fecha_limite");
            entity.Property(e => e.IdPlanPago).HasColumnName("id_plan_pago");
            entity.Property(e => e.Monto)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("monto");
            entity.Property(e => e.NumeroCuota).HasColumnName("numero_cuota");

            entity.HasOne(d => d.IdPlanPagoNavigation).WithMany(p => p.Cuota)
                .HasForeignKey(d => d.IdPlanPago)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Cuota_PlanPago");
        });

        modelBuilder.Entity<Evento>(entity =>
        {
            entity.HasKey(e => e.IdEvento);

            entity.ToTable("EVENTO", tb => tb.HasComment("Representa un evento contratado o en proceso de planificación para un cliente."));

            entity.Property(e => e.IdEvento).HasColumnName("id_evento");
            entity.Property(e => e.Estado)
                .HasMaxLength(30)
                .IsUnicode(false)
                .HasDefaultValue("Pendiente")
                .HasColumnName("estado");
            entity.Property(e => e.FechaEvento).HasColumnName("fecha_evento");
            entity.Property(e => e.FechaFin).HasColumnName("fecha_fin");
            entity.Property(e => e.FotoEventoUrl)
                .HasMaxLength(500)
                .IsUnicode(false)
                .HasColumnName("foto_evento_url");
            entity.Property(e => e.IdCliente).HasColumnName("id_cliente");
            entity.Property(e => e.IdCotizacion).HasColumnName("id_cotizacion");
            entity.Property(e => e.IdTipoEvento).HasColumnName("id_tipo_evento");
            entity.Property(e => e.IdUsuarioCoordinador).HasColumnName("id_usuario_coordinador");
            entity.Property(e => e.Lugar)
                .HasMaxLength(250)
                .IsUnicode(false)
                .HasColumnName("lugar");
            entity.Property(e => e.Nombre)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("nombre");
            entity.Property(e => e.NumeroInvitados).HasColumnName("numero_invitados");

            entity.HasOne(d => d.IdClienteNavigation).WithMany(p => p.Eventos)
                .HasForeignKey(d => d.IdCliente)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_EVENTO_CLIENTE");

            entity.HasOne(d => d.IdCotizacionNavigation).WithMany(p => p.Eventos)
                .HasForeignKey(d => d.IdCotizacion)
                .HasConstraintName("FK_EVENTO_COTIZACION");

            entity.HasOne(d => d.IdTipoEventoNavigation).WithMany(p => p.Eventos)
                .HasForeignKey(d => d.IdTipoEvento)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Evento_TipoEvento");

            entity.HasOne(d => d.IdUsuarioCoordinadorNavigation).WithMany(p => p.Eventos)
                .HasForeignKey(d => d.IdUsuarioCoordinador)
                .HasConstraintName("FK_EVENTO_COORDINADOR");
        });

        modelBuilder.Entity<EventoProveedor>(entity =>
        {
            entity.HasKey(e => e.IdEventoProveedor).HasName("PK__EVENTO_P__F89342B38D373714");

            entity.ToTable("EVENTO_PROVEEDOR");

            entity.Property(e => e.IdEventoProveedor).HasColumnName("id_evento_proveedor");
            entity.Property(e => e.CostoAcordado)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("costo_acordado");
            entity.Property(e => e.EstadoOperativo)
                .HasMaxLength(30)
                .IsUnicode(false)
                .HasDefaultValue("Pendiente")
                .HasColumnName("estado_operativo");
            entity.Property(e => e.EvidenciaUrl)
                .HasMaxLength(500)
                .IsUnicode(false)
                .HasColumnName("evidencia_url");
            entity.Property(e => e.HoraLlegada)
                .HasColumnType("datetime")
                .HasColumnName("hora_llegada");
            entity.Property(e => e.HoraPactada)
                .HasColumnType("datetime")
                .HasColumnName("hora_pactada");
            entity.Property(e => e.HoraSalida)
                .HasColumnType("datetime")
                .HasColumnName("hora_salida");
            entity.Property(e => e.IdEvento).HasColumnName("id_evento");
            entity.Property(e => e.IdServicioProveedor).HasColumnName("id_servicio_proveedor");
            entity.Property(e => e.IdUsuarioCheckin).HasColumnName("id_usuario_checkin");
            entity.Property(e => e.Observaciones)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("observaciones");

            entity.HasOne(d => d.IdEventoNavigation).WithMany(p => p.EventoProveedors)
                .HasForeignKey(d => d.IdEvento)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_EventoProveedor_Evento");

            entity.HasOne(d => d.IdServicioProveedorNavigation).WithMany(p => p.EventoProveedors)
                .HasForeignKey(d => d.IdServicioProveedor)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_EventoProveedor_Servicio");

            entity.HasOne(d => d.IdUsuarioCheckinNavigation).WithMany(p => p.EventoProveedors)
                .HasForeignKey(d => d.IdUsuarioCheckin)
                .HasConstraintName("FK_EventoProveedor_UsuarioCheckIn");
        });

        modelBuilder.Entity<IncidenciaTarea>(entity =>
        {
            entity.HasKey(e => e.IdIncidencia).HasName("PK__INCIDENC__D7757E764582D1DC");

            entity.ToTable("INCIDENCIA_TAREA");

            entity.Property(e => e.IdIncidencia).HasColumnName("id_incidencia");
            entity.Property(e => e.FechaHora)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("fecha_hora");
            entity.Property(e => e.FotoUrl)
                .HasMaxLength(500)
                .IsUnicode(false)
                .HasColumnName("foto_url");
            entity.Property(e => e.IdTarea).HasColumnName("id_tarea");
            entity.Property(e => e.Observacion).HasColumnName("observacion");

            entity.HasOne(d => d.IdTareaNavigation).WithMany(p => p.IncidenciaTareas)
                .HasForeignKey(d => d.IdTarea)
                .HasConstraintName("FK_Incidencia_Tarea");
        });

        modelBuilder.Entity<PagoCliente>(entity =>
        {
            entity.HasKey(e => e.IdPagoCliente).HasName("PK__PAGO_CLI__CCB04FF6E9495A13");

            entity.ToTable("PAGO_CLIENTE");

            entity.Property(e => e.IdPagoCliente).HasColumnName("id_pago_cliente");
            entity.Property(e => e.Estado)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("estado");
            entity.Property(e => e.FechaPago)
                .HasColumnType("datetime")
                .HasColumnName("fecha_pago");
            entity.Property(e => e.IdCuota).HasColumnName("id_cuota");
            entity.Property(e => e.MetodoPago)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("metodo_pago");
            entity.Property(e => e.Monto)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("monto");

            entity.HasOne(d => d.IdCuotaNavigation).WithMany(p => p.PagoClientes)
                .HasForeignKey(d => d.IdCuota)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PagoCliente_Cuota");
        });

        modelBuilder.Entity<PagoProveedor>(entity =>
        {
            entity.HasKey(e => e.IdPagoProveedor).HasName("PK__PAGO_PRO__CC2C4208B049859B");

            entity.ToTable("PAGO_PROVEEDOR");

            entity.Property(e => e.IdPagoProveedor).HasColumnName("id_pago_proveedor");
            entity.Property(e => e.Estado)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("estado");
            entity.Property(e => e.FechaPago)
                .HasColumnType("datetime")
                .HasColumnName("fecha_pago");
            entity.Property(e => e.IdEventoProveedor).HasColumnName("id_evento_proveedor");
            entity.Property(e => e.MetodoPago)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("metodo_pago");
            entity.Property(e => e.Monto)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("monto");

            entity.HasOne(d => d.IdEventoProveedorNavigation).WithMany(p => p.PagoProveedors)
                .HasForeignKey(d => d.IdEventoProveedor)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PagoProveedor_EventoProveedor");
        });

        modelBuilder.Entity<PlanPago>(entity =>
        {
            entity.HasKey(e => e.IdPlanPago).HasName("PK__PLAN_PAG__E9D5CC9B607EE933");

            entity.ToTable("PLAN_PAGO");

            entity.HasIndex(e => e.IdContrato, "UQ__PLAN_PAG__FF5F2A572C47D121").IsUnique();

            entity.Property(e => e.IdPlanPago).HasColumnName("id_plan_pago");
            entity.Property(e => e.Estado)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("estado");
            entity.Property(e => e.IdContrato).HasColumnName("id_contrato");
            entity.Property(e => e.NumeroCuotas).HasColumnName("numero_cuotas");

            entity.HasOne(d => d.IdContratoNavigation).WithOne(p => p.PlanPago)
                .HasForeignKey<PlanPago>(d => d.IdContrato)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PlanPago_Contrato");
        });

        modelBuilder.Entity<Proveedor>(entity =>
        {
            entity.HasKey(e => e.IdProveedor);

            entity.ToTable("PROVEEDOR", tb => tb.HasComment("Almacena la información de los proveedores externos utilizados por la empresa."));

            entity.Property(e => e.IdProveedor).HasColumnName("id_proveedor");
            entity.Property(e => e.Activo)
                .HasDefaultValue(true)
                .HasColumnName("activo");
            entity.Property(e => e.ApellidoMaterno)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("apellido_materno");
            entity.Property(e => e.ApellidoPaterno)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("apellido_paterno");
            entity.Property(e => e.Banco)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("banco");
            entity.Property(e => e.ClabeInterbancaria)
                .HasMaxLength(18)
                .IsUnicode(false)
                .HasColumnName("clabe_interbancaria");
            entity.Property(e => e.Correo)
                .HasMaxLength(150)
                .IsUnicode(false)
                .HasColumnName("correo");
            entity.Property(e => e.Descripcion)
                .HasMaxLength(500)
                .IsUnicode(false)
                .HasColumnName("descripcion");
            entity.Property(e => e.Direccion)
                .HasMaxLength(250)
                .IsUnicode(false)
                .HasColumnName("direccion");
            entity.Property(e => e.FotoProveedorUrl)
                .HasMaxLength(500)
                .IsUnicode(false)
                .HasColumnName("foto_proveedor_url");
            entity.Property(e => e.Nombre)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("nombre");
            entity.Property(e => e.Telefono)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("telefono");
            entity.Property(e => e.TitularCuenta)
                .HasMaxLength(150)
                .IsUnicode(false)
                .HasColumnName("titular_cuenta");
        });

        modelBuilder.Entity<ProveedorCategorium>(entity =>
        {
            entity.HasKey(e => e.IdProveedorCategoria);

            entity.ToTable("PROVEEDOR_CATEGORIA", tb => tb.HasComment("Representa la relación muchos a muchos entre proveedores y categorías."));

            entity.HasIndex(e => new { e.IdProveedor, e.IdCategoria }, "UQ_PROVEEDOR_CATEGORIA").IsUnique();

            entity.Property(e => e.IdProveedorCategoria).HasColumnName("id_proveedor_categoria");
            entity.Property(e => e.IdCategoria).HasColumnName("id_categoria");
            entity.Property(e => e.IdProveedor).HasColumnName("id_proveedor");

            entity.HasOne(d => d.IdCategoriaNavigation).WithMany(p => p.ProveedorCategoria)
                .HasForeignKey(d => d.IdCategoria)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PROVEEDOR_CATEGORIA_CATEGORIA");

            entity.HasOne(d => d.IdProveedorNavigation).WithMany(p => p.ProveedorCategoria)
                .HasForeignKey(d => d.IdProveedor)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PROVEEDOR_CATEGORIA_PROVEEDOR");
        });

        modelBuilder.Entity<Rol>(entity =>
        {
            entity.HasKey(e => e.IdRol).HasName("PK__ROL__6ABCB5E0D4946A98");

            entity.ToTable("ROL");

            entity.HasIndex(e => e.Nombre, "UQ__ROL__72AFBCC6E6B2A235").IsUnique();

            entity.Property(e => e.IdRol).HasColumnName("id_rol");
            entity.Property(e => e.Nombre)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("nombre");
        });

        modelBuilder.Entity<Servicio>(entity =>
        {
            entity.HasKey(e => e.IdServicio);

            entity.ToTable("SERVICIO", tb => tb.HasComment("Contiene el catálogo de servicios que ofrece la empresa organizadora de eventos."));

            entity.Property(e => e.IdServicio).HasColumnName("id_servicio");
            entity.Property(e => e.Activo)
                .HasDefaultValue(true)
                .HasColumnName("activo");
            entity.Property(e => e.Descripcion)
                .HasMaxLength(500)
                .IsUnicode(false)
                .HasColumnName("descripcion");
            entity.Property(e => e.Nombre)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("nombre");
            entity.Property(e => e.Precio)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("precio");
        });

        modelBuilder.Entity<ServicioProveedor>(entity =>
        {
            entity.HasKey(e => e.IdServicioProveedor);

            entity.ToTable("SERVICIO_PROVEEDOR", tb => tb.HasComment("Almacena los servicios que ofrece cada proveedor y su costo de referencia."));

            entity.HasIndex(e => new { e.IdProveedor, e.IdServicioProveedor }, "UQ_SERVICIO_PROVEEDOR").IsUnique();

            entity.Property(e => e.IdServicioProveedor).HasColumnName("id_servicio_proveedor");
            entity.Property(e => e.Activo)
                .HasDefaultValue(true)
                .HasColumnName("activo");
            entity.Property(e => e.Costo)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("costo");
            entity.Property(e => e.Descripcion)
                .HasMaxLength(500)
                .IsUnicode(false)
                .HasColumnName("descripcion");
            entity.Property(e => e.IdProveedor).HasColumnName("id_proveedor");
            entity.Property(e => e.NombreServicio)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("nombre_servicio");
            entity.Property(e => e.UnidadCobro)
                .HasMaxLength(30)
                .IsUnicode(false)
                .HasDefaultValue("Por evento")
                .HasColumnName("unidad_cobro");

            entity.HasOne(d => d.IdProveedorNavigation).WithMany(p => p.ServicioProveedors)
                .HasForeignKey(d => d.IdProveedor)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_SERVICIO_PROVEEDOR_PROVEEDOR");
        });

        modelBuilder.Entity<Tarea>(entity =>
        {
            entity.HasKey(e => e.IdTarea);

            entity.ToTable("TAREA", tb => tb.HasComment("Almacena las tareas necesarias para planificar y dar seguimiento a un evento."));

            entity.Property(e => e.IdTarea).HasColumnName("id_tarea");
            entity.Property(e => e.Descripcion)
                .HasMaxLength(500)
                .IsUnicode(false)
                .HasColumnName("descripcion");
            entity.Property(e => e.Estado)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasDefaultValue("Pendiente")
                .HasColumnName("estado");
            entity.Property(e => e.FechaLimite)
                .HasColumnType("datetime")
                .HasColumnName("fecha_limite");
            entity.Property(e => e.IdEvento).HasColumnName("id_evento");
            entity.Property(e => e.IdUsuario).HasColumnName("id_usuario");
            entity.Property(e => e.Nombre)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("nombre");

            entity.HasOne(d => d.IdEventoNavigation).WithMany(p => p.Tareas)
                .HasForeignKey(d => d.IdEvento)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_TAREA_EVENTO");

            entity.HasOne(d => d.IdUsuarioNavigation).WithMany(p => p.Tareas)
                .HasForeignKey(d => d.IdUsuario)
                .HasConstraintName("FK_TAREA_USUARIO");
        });

        modelBuilder.Entity<TipoEvento>(entity =>
        {
            entity.HasKey(e => e.IdTipoEvento).HasName("PK__TIPO_EVE__E3566D792EBB1493");

            entity.ToTable("TIPO_EVENTO");

            entity.HasIndex(e => e.Nombre, "UQ__TIPO_EVE__72AFBCC6F9E89FE4").IsUnique();

            entity.Property(e => e.IdTipoEvento).HasColumnName("id_tipo_evento");
            entity.Property(e => e.Activo)
                .HasDefaultValue(true)
                .HasColumnName("activo");
            entity.Property(e => e.Descripcion)
                .HasMaxLength(150)
                .IsUnicode(false)
                .HasColumnName("descripcion");
            entity.Property(e => e.Nombre)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("nombre");
        });

        modelBuilder.Entity<Usuario>(entity =>
        {
            entity.HasKey(e => e.IdUsuario);

            entity.ToTable("USUARIO", tb => tb.HasComment("Almacena las cuentas de acceso de todos los usuarios del sistema y su rol."));

            entity.HasIndex(e => e.Correo, "UQ_USUARIO_CORREO").IsUnique();

            entity.Property(e => e.IdUsuario).HasColumnName("id_usuario");
            entity.Property(e => e.Activo)
                .HasDefaultValue(true)
                .HasColumnName("activo");
            entity.Property(e => e.ApellidoMaterno)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("apellido_materno");
            entity.Property(e => e.ApellidoPaterno)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("apellido_paterno");
            entity.Property(e => e.Contrasenia)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("contrasenia");
            entity.Property(e => e.Correo)
                .HasMaxLength(150)
                .IsUnicode(false)
                .HasColumnName("correo");
            entity.Property(e => e.FotoUrl)
                .HasMaxLength(500)
                .IsUnicode(false)
                .HasColumnName("foto_url");
            entity.Property(e => e.IdRol).HasColumnName("id_rol");
            entity.Property(e => e.Nombre)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("nombre");

            entity.HasOne(d => d.IdRolNavigation).WithMany(p => p.Usuarios)
                .HasForeignKey(d => d.IdRol)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Usuario_Rol");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
