FROM ros:noetic

WORKDIR /code

COPY ./requirements.txt /code/
COPY ./ /code/

RUN apt-get update \
    && apt-get install -q -y python3-pip \
    && apt-get install -q -y ros-noetic-cv-bridge \
    && apt-get install -q -y python3-opencv

RUN pip3 install --ignore-installed -r requirements.txt

# RUN echo 'source /opt/ros/noetic/setup.bash' >> /root/.bashrc
SHELL ["/bin/bash", "-c"]
RUN source /opt/ros/noetic/setup.bash