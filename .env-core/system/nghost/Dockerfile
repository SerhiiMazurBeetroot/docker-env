FROM python:3.13-alpine

RUN pip3 install docker
RUN mkdir /nghost
WORKDIR /nghost
ADD nghost.py /nghost/

CMD ["python3", "-u", "nghost.py"]


