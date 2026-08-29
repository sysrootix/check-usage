.PHONY: project icon test app clean

project: icon
	xcodegen generate

icon:
	swift scripts/make-icon.swift Resources/Assets.xcassets/AppIcon.appiconset

test: project
	xcodebuild test \
		-project CheckUsage.xcodeproj \
		-scheme CheckUsage \
		-destination 'platform=macOS' \
		CODE_SIGNING_ALLOWED=NO \
		-quiet

app: project
	rm -rf dist/CheckUsage.app
	mkdir -p dist
	xcodebuild -project CheckUsage.xcodeproj \
		-scheme CheckUsage \
		-configuration Release \
		-derivedDataPath build/DerivedData \
		SYMROOT="$(CURDIR)/build/Products" \
		CODE_SIGN_IDENTITY="-" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO
	cp -R build/Products/Release/CheckUsage.app dist/CheckUsage.app
	@echo "Built dist/CheckUsage.app"

clean:
	rm -rf build dist CheckUsage.xcodeproj .swiftpm
