YEAR=$(shell grep Package packageinfo/control | cut -c 13-16)
VER=$(shell grep Version packageinfo/control | cut -c 10-)
IPK_NAME=frc${YEAR}-libprotobuf_${VER}_cortexa9-vfpv3.ipk
DOCKER_IMAGE=roborio-cross-${YEAR}-t195

ipk: build/${IPK_NAME}
	
libprotobuf: build/libprotobuf_${VER}.so

build/libprotobuf_${VER}.so:
	mkdir -p build
	docker run --rm -v ${PWD}/build:/artifacts -v ${PWD}/packageinfo:/packageinfo ${DOCKER_IMAGE} /bin/bash -c '\
		curl -SLO https://github.com/protocolbuffers/protobuf/releases/download/v${VER}/protobuf-cpp-${VER}.tar.gz \
		&& tar xzf protobuf-cpp-${VER}.tar.gz \
		&& cd protobuf-${VER} \
		&& ./configure --host=arm-frc${YEAR}-linux-gnueabi CC=arm-frc${YEAR}-linux-gnueabi-gcc CXX=arm-frc${YEAR}-linux-gnueabi-g++ \
		&& cd src \
		&& make -j4 \
		&& chown -R `id -u`:`id -g` .libs/libprotobuf.so \
		&& chown -R `id -u`:`id -g` .libs/protoc \
		&& arm-frc${YEAR}-linux-gnueabi-strip .libs/libprotobuf.so \
		&& cp .libs/libprotobuf.so /artifacts/libprotobuf_${VER}.so \
		&& cp .libs/protoc /artifacts/protoc'
	
clean:
	docker run --rm -v ${PWD}/build:/artifacts -v ${PWD}/packageinfo:/packageinfo ${DOCKER_IMAGE} /bin/bash -c '\
		cd /artifacts \
		&& rm -f libprotobuf_${VER}.so \
		&& rm -f control.tar.gz \
		&& rm -f data.tar.gz \
		&& rm -f debian-binary \
		&& rm -f ${IPK_NAME} '
	
build/${IPK_NAME}: build/libprotobuf_${VER}.so
	docker run --rm -v ${PWD}/build:/artifacts -v ${PWD}/packageinfo:/packageinfo ${DOCKER_IMAGE} /bin/bash -c '\
		cd /artifacts \
		&& chmod 775 -R ./ \
		&& tar cvJf data.tar.xz --transform "s,^artifacts,usr/lib," --show-transformed-names --exclude=\*.diz --owner=root --group=root /artifacts/*.so || true \
		&& tar czf control.tar.gz /packageinfo/control /packageinfo/postinst /packageinfo/prerm || true \
		&& echo 2.0 > debian-binary \
		&& /usr/local/arm-frc${YEAR}-linux-gnueabi/bin/ar r ${IPK_NAME} control.tar.gz data.tar.xz debian-binary \
		&& rm -f /artifacts/control.tar.gz \
		&& rm -f /artifacts/data.tar.xz \
		&& rm -f /artifacts/debian-binary'
	cp build/${IPK_NAME} ${IPK_NAME}
	
include buildenv/Makefile