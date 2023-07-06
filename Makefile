 CFLAGS = -Wall -Wextra -Wno-deprecated-declarations

#ifeq ($(DEBUG),1)
	GRAMINE_LOG_LEVEL = debug
#	CFLAGS += -g
#else
#	GRAMINE_LOG_LEVEL = error
#	CFLAGS += -O3
#endif

LDFLAGS = $(CFLAGS) -L/usr/lib/x86_64-linux-gnu/sgx -lcrypto

.PHONY: all
all: test-gramine test-gramine.manifest
#ifeq ($(SGX),1)
#	all: test-gramine.manifest.sgx test-gramine.sig
#endif
ifeq ($(SGX),1)
	gramine-manifest -Dlog_level=error test-gramine.manifest.template test-gramine.manifest
	#make
	gramine-sgx-sign --manifest test-gramine.manifest --output test-gramine.manifest.sgx
endif
test-gramine: test-gramine.o
	$(CC) $^ -o $@ $(LDFLAGS) -lssl -lcrypto

test-gramine.o: test-gramine.c

test-gramine.manifest: test-gramine.manifest.template
	gramine-manifest -Dlog_level=$(GRAMINE_LOG_LEVEL) $< $@

test-gramine.sig test-gramine.manifest.sgx: sgx_sign
	@:

.INTERMEDIATE: sgx_sign
sgx_sign: test-gramine.manifest test-gramine
	gramine-sgx-sign --manifest $< --output $<.sgx

ifeq ($(SGX),)
	GRAMINE = LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu gramine-direct
else
	GRAMINE = LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu gramine-sgx
endif

.PHONY: check
check: all
	$(GRAMINE) ./test-gramine <input-file> | $(SHA512_CMD) > OUTPUT
	echo "SHA512 hash of input file:"
	cat OUTPUT
	@echo "[ Success ]"

.PHONY: clean
clean:
	$(RM) *.token *.sig *.manifest.sgx *.manifest test-gramine.o test-gramine OUTPUT

.PHONY: distclean
distclean: clean
	rm -rf .gbuild

SHA512_CMD = sha512sum
