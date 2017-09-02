package programs

import (
	"fmt"
	"path/filepath"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type Tmux struct{}

func (tmux Tmux) Name() string {
	return "tmux"
}

func (tmux Tmux) URL(version string) string {
	return fmt.Sprintf("https://github.com/tmux/tmux/releases/download/%s/tmux-%s.tar.gz", version, version)
}

func (tmux Tmux) Build(config sift.Config) error {
	libevent := Libevent{}
	ncurses := Ncurses{}

	configure := sift.ConfigureCmd{
		Prefix: config.Prefix,
		Args: []string {
			// If we use --enable-static, we get the following warnings like:
			// cmd-string.c:(.text+0x844): warning: Using 'getpwnam' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
			// These functions will break and may cause the program to crash.
			// So we just generate a pseudo-static tmux instead, that links to system libraries
			// TODO: Revisit once using musl
			// "--enable-static",
		},
		CFlags: []string{
			"-I" + config.IncludeDir(libevent),
			"-I" + config.IncludeDir(ncurses),
		},
		LdFlags: []string{
			"-L" + config.LibDir(libevent),
			"-L" + config.LibDir(ncurses),
		},
		PkgConfigPaths: []string{
			filepath.Join(config.InstallDir(ncurses), "share", "pkgconfig"),
		},
	}.Cmd()
	configure.Env = append(
		configure.Env,
		"LIBNCURSES_CFLAGS=-D_GNU_SOURCE",
		"LIBNCURSES_LIBS=-lncursesw -ltinfow",
	)

	if err := configure.Run(); err != nil {
		return err
	}
	make := sift.MakeCmd{Jobs: config.NumCores}.Cmd()
	return make.Run()
}

func (tmux Tmux) Install(config sift.Config) error {
	make := sift.MakeCmd{
		Args: []string{
			"install",
			"prefix=" + config.InstallDir(tmux),
		},
	}.Cmd()
	return make.Run()
}

func (tmux Tmux) Dependencies() []sift.Package {
	return []sift.Package{
		Libevent{},
		Ncurses{},
	}
}
