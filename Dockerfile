# Ansible managed
# !!! Do not edit this file manually !!!

FROM	alpine:3.10 AS base_image
RUN		apk --no-cache add \
			python3==3.7.5-r1 \
			curl==7.66.0-r0 \
			ca-certificates==20190108-r0 \
			git==2.22.2-r0 \
			openssh-client==8.1_p1-r0 \
			rsync==3.1.3-r1 \
			bash==5.0.0-r0 \
		&& pip3 install pip==19.2.3 --upgrade \
		&& pip3 install wheel==0.33.6 \
		&& ln -s /usr/bin/python3 /usr/bin/python \
		&& update-ca-certificates

FROM	base_image AS pip_packages
WORKDIR	/build
COPY	requirements.pip.txt .
RUN		apk --no-cache add \
			python3-dev==3.7.5-r1 \
			gcc==8.3.0-r0 \
			musl-dev==1.1.22-r3 \
			libffi-dev==3.2.1-r6 \
			openssl-dev==1.1.1d-r0 \
			make==4.2.1-r2 \
		&& pip3 wheel -r requirements.pip.txt

FROM	base_image AS third_party
WORKDIR	/build
RUN		curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" \
		&& chmod +x ./kubectl

FROM    pip_packages
FROM    third_party
FROM	base_image
ARG		BUILD_DATE
ARG		DOCKER_REPO
ARG		VCS_REF
ARG		DOCKER_TAG=latest
COPY	--from=pip_packages /build /wheels
COPY	--from=third_party /build/* /usr/local/bin/
RUN		pip3 install -r /wheels/requirements.pip.txt -f /wheels --no-cache-dir \
	    && rm -rf /wheels \
		&& rm -rf /root/.cache/pip/* \
		&& rm -rf /var/cache/apk/*
LABEL	name=${DOCKER_REPO} \
		version=${DOCKER_TAG} \
		org.label-schema.name=${DOCKER_REPO} \
		org.label-schema.build-date=${BUILD_DATE} \
		org.label-schema.vcs-url=${DOCKER_REPO} \
		org.label-schema.vcs-ref=${VCS_REF} \
		org.label-schema.schema-version=${DOCKER_TAG} \
		org.label-schema.version=${DOCKER_TAG}
