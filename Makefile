YEAR=$(shell grep Package packageinfo/control | cut -c 13-16)
VER=$(shell grep Version packageinfo/control | cut -c 10-)
IPK_NAME=frc${YEAR}-libzmq_${VER}_cortexa9-vfpv3.ipk
DOCKER_IMAGE=roborio-cross-${YEAR}-t195

ipk: build/${IPK_NAME}
	
libzmq: build/libzmq_${VER}.so

build/libzmq_${VER}.so:
	mkdir -p build
	docker run --rm -v ${PWD}/build:/artifacts ${DOCKER_IMAGE} /bin/bash -c '\
		curl -SLO https://github.com/zeromq/libzmq/releases/download/v${VER}/zeromq-${VER}.tar.gz \
		&& tar xzf zeromq-${VER}.tar.gz \
		&& cd zeromq-${VER} \
		&& ./configure --host=arm-frc${YEAR}-linux-gnueabi CC=arm-frc${YEAR}-linux-gnueabi-gcc CXX=arm-frc${YEAR}-linux-gnueabi-g++ \
		&& make -j4 \
		&& chown -R `id -u`:`id -g` src/.libs/libzmq.so \
		&& arm-frc${YEAR}-linux-gnueabi-strip src/.libs/libzmq.so \
		&& cp src/.libs/libzmq.so /artifacts/libzmq_${VER}.so'
	
clean:
	docker run --rm -v ${PWD}/build:/artifacts ${DOCKER_IMAGE} /bin/bash -c '\
		cd /artifacts \
		&& rm -f libzmq_${VER}.so \
		&& rm -f control.tar.gz \
		&& rm -f data.tar.gz \
		&& rm -f debian-binary \
		&& rm -f ${IPK_NAME} '
	
build/${IPK_NAME}: build/libzmq_${VER}.so
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
	
include buildenv/Makefile