repository_get() {
	repo="$1"
	rev="$2"
	name=$(basename "$repo")
	if ! test -d "$name"
	then
		echo "Cloning repository..."
		git clone -q "$repo" "$name"
	fi
	git -C "$name" checkout master
	git -C "$name" pull
	git -C "$name" checkout -q $rev
	echo "Repository: $(git -C "$name" remote get-url origin)" >&2
	echo "Revision: $(git -C "$name" rev-parse HEAD)" >&2
}

repository_build() {
	repo="$1"
	rev="$2"
	name=$(basename "$repo")
	dir="$name/$3"
	options="$4"
	repository_get "$repo" "$rev"
	echo "Building with $options ..."
	if ! test -d $dir
	then
		mkdir -p "$dir"
		meson --buildtype=release "$name" "$dir"
	fi
	meson configure $dir $options
	ninja -C $dir
}
