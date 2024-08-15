@echo off

REM Create a virtual environment
python -m venv venv

REM Activate the virtual environment
call venv\Scripts\activate

REM Upgrade pip
pip install --upgrade pip

REM Install requirements
pip install -r requirements.txt

echo Virtual environment setup complete. Activate it with 'venv\Scripts\activate'
