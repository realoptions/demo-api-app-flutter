wget -O ./mocks/openapi.yaml https://raw.githubusercontent.com/realoptions/option_price_faas/master/docs/openapi_merged.yml

wget -O ./mocks/apisprout.tar.xz https://github.com/danielgtaylor/apisprout/releases/download/v1.3.0/apisprout-v1.3.0-linux.tar.xz

tar xf ./mocks/apisprout.tar.xz -C ./mocks
rm ./mocks/apisprout.tar.xz 