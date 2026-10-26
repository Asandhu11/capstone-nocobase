FROM python:3.12-slim

WORKDIR /tests

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . /tests

CMD ["pytest", "-q", "/tests/test_sprint4_roles.py", "-p", "no:cacheprovider"]
