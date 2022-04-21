
# Run
# security find-identity -p codesigning
# to see your code sign find-identity

CONFIG?=release

all:
	swift build -c ${CONFIG}
	rm -f -- DarwinCracker
	cp .build/x86_64-apple-macosx/${CONFIG}/DarwinCracker DarwinCracker
	codesign -s "${CODESIGN_IDENTITY}" --entitlements DarwinCracker.entitlements DarwinCracker

README.html: README.md www/clean.css Makefile
	pandoc -s -f markdown+smart --toc --metadata pagetitle="DarwinCracker" --to=html5 README.md -o "$@"

.PHONY: all
