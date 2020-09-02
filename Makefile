.PHONY : typechain compile test compile-clean console run deploy

typechain:
	./node_modules/.bin/typechain --target ethers-v5 --outDir typechain './artifacts/*.json'

compile:
	npx buidler compile
	cp -R artifacts/** app/src/build

compile-clean:
	npx buidler clean
	make compile

test:
	npm run-script test test/StreamTest.ts

run-node:
	@npx buidler node

deploy:
	npx buidler run deployTest.ts