FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt ./requirements.txt

# requirements.txt in this repo is UTF-16; normalize to UTF-8 for pip.
RUN python -c "import pathlib; p=pathlib.Path('requirements.txt'); b=p.read_bytes(); text=b.decode('utf-16') if b.startswith((b'\\xff\\xfe', b'\\xfe\\xff')) else b.decode('utf-8'); pathlib.Path('requirements.docker.txt').write_text(text, encoding='utf-8')" \
    && pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.docker.txt

COPY app ./app

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
