FROM gcr.io/spinnaker-marketplace/gradle_cache as builder
MAINTAINER delivery-engineering@netflix.com

ENV GRADLE_USER_HOME /gradle_cache/.gradle
COPY . compiled_sources
WORKDIR compiled_sources

RUN ./gradlew installDist -x test

FROM alpine:3.11
MAINTAINER delivery-engineering@netflix.com
COPY --from=builder /compiled_sources/custom-crd-extension/build/install/clouddriver /opt/clouddriver

ENV KUBECTL_VERSION v1.16.0

RUN apk --no-cache add --update bash wget unzip openjdk8 'python2>2.7.9' && \
  wget -nv https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.zip && \
  unzip -qq google-cloud-sdk.zip -d /opt && \
  rm google-cloud-sdk.zip && \
  CLOUDSDK_PYTHON="python2.7" /opt/google-cloud-sdk/install.sh --usage-reporting=false --bash-completion=false --additional-components app-engine-java && \
  rm -rf ~/.config/gcloudB

RUN wget https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
  chmod +x kubectl && \
  mv ./kubectl /usr/local/bin/kubectl

RUN wget https://amazon-eks.s3-us-west-2.amazonaws.com/1.13.7/2019-06-11/bin/linux/amd64/aws-iam-authenticator && \
  chmod +x ./aws-iam-authenticator && \
  mv ./aws-iam-authenticator /usr/local/bin/aws-iam-authenticator && \
  ln -sf /usr/local/bin/aws-iam-authenticator /usr/local/bin/heptio-authenticator-aws

RUN apk -v --update add py-pip && \
  pip install --upgrade awscli==1.16.258 s3cmd==2.0.1 python-magic && \
  apk -v --purge del py-pip && \
  rm /var/cache/apk/*

ENV PATH "$PATH:/usr/local/bin/"

ENV PATH=$PATH:/opt/google-cloud-sdk/bin/

RUN adduser -D -S spinnaker

USER spinnaker

CMD ["/opt/clouddriver/bin/clouddriver"]

