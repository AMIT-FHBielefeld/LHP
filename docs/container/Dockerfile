FROM sphinxdoc/sphinx

RUN mkdir -p /project/docs
WORKDIR /project/docs
ADD requirements.txt /project/docs
RUN pip3 install -r requirements.txt
