# Test runner image. The test code itself is bind-mounted at /tests by compose.yml,
# so editing a test never needs a rebuild; only the dependencies live in the image.
FROM python:3.12-slim
WORKDIR /tests
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
CMD ["pytest", "-v", "--junitxml=/artifacts/results.xml", "-p", "no:cacheprovider"]
