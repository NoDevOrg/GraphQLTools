open-in-docker:
	docker run --rm --privileged --interactive --tty --volume "$(shell pwd):/src" --workdir "/src" swift:5.10

lint:
	swift format lint --configuration ./swift-format-config.json --recursive .

format:
	swift format format --configuration ./swift-format-config.json --in-place --recursive .
