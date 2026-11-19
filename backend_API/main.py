from contextlib import asynccontextmanager
from pathlib import Path
import shutil
import uuid
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse
from urllib.request import Request as UrlRequest, urlopen

from fastapi import FastAPI, Depends, File, Form, HTTPException, Request, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from fastapi.staticfiles import StaticFiles
from pydantic import ValidationError
from sqlalchemy.orm import Session
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from pwdlib import PasswordHash
from pwdlib.hashers.argon2 import Argon2Hasher
from pwdlib.hashers.bcrypt import BcryptHasher
from database import Base, engine, obtener_sesion
from models import Usuario, Blog, Comentario
from schemas import (
    UsuarioCrear,
    UsuarioActualizar,
    UsuarioRespuesta,
    BlogRespuesta,
    BlogCrear,
    ComentarioCrear,
    ComentarioRespuesta,
    LoginRequest,
)

# PHP `password_hash(..., PASSWORD_DEFAULT)` usa bcrypt actualmente.
# BcryptHasher permite verificar también los hashes PHP con prefijo `$2y$`.
# Argon2 se conserva para que los usuarios creados con la versión anterior
# del backend puedan seguir iniciando sesión.
password_hash = PasswordHash((BcryptHasher(), Argon2Hasher()))


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Punto de extensión para tareas de inicio y cierre de la API.
    yield

app = FastAPI(
    title="API de aplicación móvil",
    lifespan=lifespan,
)

UPLOAD_DIR = Path(__file__).resolve().parent / "uploads"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")


@app.get("/")
def inicio():
    # Endpoint de comprobación para verificar que la API está activa.
    return {"mensaje": "API funcionando correctamente"}


@app.get("/image-proxy")
def proxy_imagen(url: str):
    # Descarga imágenes externas para que Flutter Web no tenga problemas de CORS.
    destino = urlparse(url)
    if destino.scheme not in {"http", "https"} or not destino.netloc:
        raise HTTPException(status_code=400, detail="La URL de imagen no es válida")

    try:
        solicitud = UrlRequest(url, headers={"User-Agent": "FlutterProject/1.0"})
        with urlopen(solicitud, timeout=10) as respuesta:
            contenido = respuesta.read(5 * 1024 * 1024 + 1)
            tipo = respuesta.headers.get_content_type()
    except (HTTPError, URLError, TimeoutError) as error:
        raise HTTPException(status_code=502, detail="No se pudo descargar la imagen externa") from error

    if len(contenido) > 5 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="La imagen supera 5 MB")
    if not tipo.startswith("image/"):
        raise HTTPException(status_code=415, detail="El enlace no apunta a una imagen")

    return Response(content=contenido, media_type=tipo, headers={"Cache-Control": "public, max-age=3600"})
# Permitir la comunicación con Flutter Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:60450",
        "http://127.0.0.1:60450",
        "http://localhost:62755",
        "http://127.0.0.1:62755",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
    ],
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.post("/login", response_model=UsuarioRespuesta)
def iniciar_sesion(
    # Busca al usuario y valida su contraseña.
    datos: LoginRequest,
    db: Session = Depends(obtener_sesion),
):
    correo = datos.mail.strip().lower()

    usuario = db.scalar(
        select(Usuario).where(Usuario.mail == correo)
    )

    # Se utiliza el mismo mensaje para no revelar
    # si el correo está registrado.
    if usuario is None or not password_hash.verify(
        datos.password,
        usuario.pass_hash,
    ):
        raise HTTPException(
            status_code=401,
            detail="Correo o contraseña incorrectos",
        )

    # Devuelve únicamente los datos públicos del usuario.
    return usuario

# Endpoints existentes:
# @app.get("/usuarios")
# @app.post("/usuarios")
# etc.

# USUARIOS

@app.get("/usuarios", response_model=list[UsuarioRespuesta])
def listar_usuarios(db: Session = Depends(obtener_sesion)):
    # Devuelve los usuarios ordenados por identificador.
    return db.scalars(
        select(Usuario).order_by(Usuario.id_usr)
    ).all()


@app.post("/usuarios", response_model=UsuarioRespuesta, status_code=201)
def crear_usuario(
    # Valida, cifra y registra un usuario nuevo.
    datos: UsuarioCrear,
    db: Session = Depends(obtener_sesion),
):
    usuario = Usuario(
        nom_usr=datos.nom_usr.strip(),
        mail=datos.mail.strip().lower(),
        pass_hash=password_hash.hash(datos.password),
        dir_usr=datos.dir_usr,
        tip_usu=datos.tip_usu,
    )

    db.add(usuario)

    try:
        db.commit()
        db.refresh(usuario)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="El correo ya está registrado",
        )

    return usuario
@app.put(
    "/usuarios/{usuario_id}",
    response_model=UsuarioRespuesta,
)
def actualizar_usuario(
    # Modifica los datos de un usuario existente.
    usuario_id: int,
    datos: UsuarioActualizar,
    db: Session = Depends(obtener_sesion),
):
    usuario = db.get(Usuario, usuario_id)

    if usuario is None:
        raise HTTPException(
            status_code=404,
            detail="Usuario no encontrado",
        )

    setattr(usuario, "nom_usr", datos.nom_usr.strip())
    setattr(usuario, "mail", datos.mail.strip().lower())
    setattr(usuario, "dir_usr", datos.dir_usr)
    setattr(usuario, "tip_usu", datos.tip_usu)

    try:
        db.commit()
        db.refresh(usuario)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="El correo ya está registrado",
        )

    return usuario


@app.delete("/usuarios/{usuario_id}")
def eliminar_usuario(
    # Elimina un usuario por su identificador.
    usuario_id: int,
    db: Session = Depends(obtener_sesion),
):
    usuario = db.get(Usuario, usuario_id)

    if usuario is None:
        raise HTTPException(
            status_code=404,
            detail="Usuario no encontrado",
        )

    db.delete(usuario)
    db.commit()

    return {"mensaje": "Usuario eliminado correctamente"}

# BLOG

@app.get("/blog", response_model=list[BlogRespuesta])
def listar_blog(db: Session = Depends(obtener_sesion)):
    # Devuelve todas las publicaciones ordenadas.
    return db.scalars(
        select(Blog).order_by(Blog.id_blog)
    ).all()

@app.post("/blog", response_model=BlogRespuesta, status_code=201)
async def crear_blog(
    # Crea una publicación desde JSON o desde un formulario multipart.
    request: Request,
    titulo: str | None = Form(default=None),
    descripcion: str | None = Form(default=None),
    imagen: UploadFile | None = File(default=None),
    tags: str | None = Form(default=None),
    db: Session = Depends(obtener_sesion),
):
    content_type = (
        request.headers.get("content-type", "")
        .split(";", 1)[0]
        .strip()
        .lower()
    )

    if content_type == "multipart/form-data":
        try:
            if not isinstance(titulo, str) or not titulo.strip():
                raise HTTPException(status_code=422, detail="El título es obligatorio")
            if len(titulo.strip()) < 2:
                raise HTTPException(
                    status_code=422,
                    detail="El título debe tener al menos 2 caracteres",
                )
            if len(titulo.strip()) > 150:
                raise HTTPException(
                    status_code=422,
                    detail="El título no puede superar 150 caracteres",
                )
            if not isinstance(descripcion, str) or not descripcion.strip():
                raise HTTPException(
                    status_code=422,
                    detail="La descripción es obligatoria",
                )
            if imagen is None:
                raise HTTPException(
                    status_code=422,
                    detail="La fotografía es obligatoria",
                )
            if tags is not None and not isinstance(tags, str):
                raise HTTPException(status_code=422, detail="Los tags no son válidos")
            if isinstance(tags, str) and len(tags.strip()) > 255:
                raise HTTPException(
                    status_code=422,
                    detail="Los tags no pueden superar 255 caracteres",
                )

            extension = Path(imagen.filename or "").suffix.lower()
            if extension not in {".jpg", ".jpeg", ".png", ".webp"}:
                raise HTTPException(
                    status_code=400,
                    detail="Formato de imagen no permitido",
                )

            nombre_archivo = f"{uuid.uuid4().hex}{extension}"
            ruta_archivo = UPLOAD_DIR / nombre_archivo
            ruta_publica = f"/uploads/{nombre_archivo}"

            try:
                with ruta_archivo.open("wb") as destino:
                    shutil.copyfileobj(imagen.file, destino)
                return _guardar_blog(
                    db,
                    titulo=titulo,
                    descripcion=descripcion,
                    img=ruta_publica,
                    tags=tags,
                )
            except (OSError, SQLAlchemyError):
                ruta_archivo.unlink(missing_ok=True)
                raise
        finally:
            if imagen is not None:
                await imagen.close()

    try:
        datos = BlogCrear.model_validate(await request.json())
    except ValidationError as error:
        raise HTTPException(
            status_code=422,
            detail=error.errors(),
        ) from error
    except ValueError as error:
        raise HTTPException(
            status_code=400,
            detail="El cuerpo JSON no es válido",
        ) from error

    return _guardar_blog(
        db,
        titulo=datos.titulo,
        descripcion=datos.descripcion,
        img=datos.img,
        tags=datos.tags,
    )


def _guardar_blog(
    # Guarda una publicación validada en la base de datos.
    db: Session,
    *,
    titulo: str,
    descripcion: str,
    img: str | None,
    tags: str | None = None,
):
    publicacion = Blog(
        titulo=titulo.strip(),
        descripcion=descripcion.strip(),
        img=img.strip() if img and img.strip() else None,
        tags=tags.strip() if tags and tags.strip() else None,
    )
    db.add(publicacion)
    try:
        db.commit()
        db.refresh(publicacion)
    except SQLAlchemyError:
        db.rollback()
        raise
    return publicacion

@app.get("/blog/{blog_id}", response_model=BlogRespuesta)
def obtener_blog(
    # Busca una publicación específica por su ID.
    blog_id: int,
    db: Session = Depends(obtener_sesion),
):
    publicacion = db.get(Blog, blog_id)

    if publicacion is None:
        raise HTTPException(
            status_code=404,
            detail="Publicación no encontrada",
        )

    return publicacion

# COMENTARIOS

@app.get(
    "/comentarios",
    response_model=list[ComentarioRespuesta],
)
def listar_comentarios(
    # Lista comentarios, opcionalmente filtrados por publicación.
    blog_id: int | None = None,
    db: Session = Depends(obtener_sesion),
):
    consulta = select(Comentario)

    if blog_id is not None:
        consulta = consulta.where(Comentario.blog_id == blog_id)

    return db.scalars(
        consulta.order_by(Comentario.id_com)
    ).all()


@app.post(
    "/comentarios",
    response_model=ComentarioRespuesta,
    status_code=201,
)
def crear_comentario(
    # Valida las relaciones y registra un comentario nuevo.
    datos: ComentarioCrear,
    db: Session = Depends(obtener_sesion),
):
    if not datos.comentario.strip():
        raise HTTPException(
            status_code=422,
            detail="El comentario no puede estar vacío",
        )

    if db.get(Usuario, datos.usr_id) is None:
        raise HTTPException(
            status_code=404,
            detail="Usuario no encontrado",
        )

    if db.get(Blog, datos.blog_id) is None:
        raise HTTPException(
            status_code=404,
            detail="Publicación no encontrada",
        )

    nuevo = Comentario(
        comentario=datos.comentario.strip(),
        usr_id=datos.usr_id,
        blog_id=datos.blog_id,
        estatus=1,
    )

    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)

    return nuevo
