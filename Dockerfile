#Version: 0.0.1

FROM macadmins/sal

MAINTAINER Nick McSpadden "nmcspadden@gmail.com"

RUN pip install python-jss
RUN git clone https://github.com/nmcspadden/Sal-WHDImport.git /home/docker/sal/whdimport
RUN git clone https://github.com/nmcspadden/MacModelShelf.git /home/docker/sal/macmodelshelf
RUN mv /home/docker/sal/macmodelshelf/macmodelshelf.py /home/docker/sal/
RUN mv /home/docker/sal/macmodelshelf/macmodelshelf.json /home/docker/sal/
RUN pip install psycopg2
RUN git clone https://github.com/nmcspadden/Sal-JSSImport.git --branch development /home/docker/sal/jssimport
