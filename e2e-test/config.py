import os

BASE_URL = os.getenv("BASE_URL", "http://localhost:13003")
REQUEST_TIMEOUT = float(os.getenv("REQUEST_TIMEOUT", "15"))

HEALTHCHECK_PATH = "/api/pm:listEnabled"
HOME_PATH = "/"
