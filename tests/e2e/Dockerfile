FROM python:3.12-slim
WORKDIR /tests
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
CMD ["pytest", "-v", "-p", "no:cacheprovider"]
