open-in-docker:
	docker run --rm --privileged --interactive --tty --volume "$(shell pwd):/src" --workdir "/src" swift:5.10
