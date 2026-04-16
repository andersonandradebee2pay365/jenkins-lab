FROM python:3.11-slim

# Atualiza pacotes do sistema para corrigir vulnerabilidades com fix disponível
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --upgrade

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]