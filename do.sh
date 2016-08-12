#!/bin/bash
_CURRENT_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
_CURRENT_RUNNING_DIR="$( cd "$( dirname "." )" && pwd )"
source $_CURRENT_FILE_DIR/stella-link.sh include

# NOTE :
# general recipes : http://codegists.com/code/install-tensorflow-aws/
# cuda recipes macos :
#				https://medium.com/@fabmilo/how-to-compile-tensorflow-with-cuda-support-on-osx-fd27108e27e1#.lxfax6s4q
#				https://docs.google.com/document/d/1f0y8t28c_VltOx4mZDSUCozuAslejT4f_QlATKX82Uw/edit
#
# CoNLL format : https://github.com/tensorflow/models/blob/master/syntaxnet/syntaxnet/text_formats.cc

# french treebank 1 https://gforge.inria.fr/projects/fdtb-v1
# UniversalDependencies french : https://github.com/UniversalDependencies/UD_French

function usage() {
	echo "USAGE :"
	echo "----------------"
	echo "L     syntaxnet install|uninstall|build|test : deploy/undeploy/build/test syntaxnet"
	echo "L     lang install [-l=<lang>]: download a pretrained model (for lang see : https://github.com/tensorflow/models/blob/master/syntaxnet/universal.md)"
	echo "L     lang test [-l=<lang>] -- <test_text> : test pretrained model with <test_text>"
	echo "L			train test"

}

# COMMAND LINE -----------------------------------------------------------------------------------
PARAMETERS="
DOMAIN=											'domain' 			a				'syntaxnet lang train'
ACTION=												'' 					a				'install uninstall build run test'
"
OPTIONS="
FORCE=''				   'f'		  ''					b			0		'1'					  Force.
OPT='default_val' 						'' 			'string'				s 			0			''		  Sample option.
L='English'					'l'			'language'		s			0				''		Language.
"
$STELLA_API argparse "$0" "$OPTIONS" "$PARAMETERS" "syntaxnet_test" "$(usage)" "APPARG" "$@"

#-------------------------------------------------------------------------------------------

TENSORFLOW_MODELS_HOME="$STELLA_APP_ROOT/tensorflow_models"
SYNTAXNET_HOME="$TENSORFLOW_MODELS_HOME/models/syntaxnet"
SYNTAXNET_PYTHON_VERSION="2.7.12"
SYNTAXNET_PYTHON_ENV="syntaxnet_env"
TRAINED_MODEL_HOME="$STELLA_APP_ROOT/models"
PRETRAINED_MODEL_HOME="$TRAINED_MODEL_HOME/pretrained"

# --------------- TRAIN ----------------------------
if [ "$DOMAIN" == "train" ]; then

	mkdir -p "$TRAINED_MODEL_HOME"

	echo "TODO"
fi


# --------------- LANG ----------------------------
if [ "$DOMAIN" == "lang" ]; then

	mkdir -p "$PRETRAINED_MODEL_HOME"

	if [ "$ACTION" == "install" ]; then
		echo "** Install pre-trained model for $L"
		$STELLA_API get_resource "Model $L" "http://download.tensorflow.org/models/parsey_universal/$L.zip" "HTTP_ZIP" "$PRETRAINED_MODEL_HOME"
		if [ ! -d "$PRETRAINED_MODEL_HOME/$L" ]; then
			echo "** ERROR $L do not exist"
			exit 1
		fi
	fi

	if [ "$ACTION" == "test" ]; then
		echo "** Test pre-trained model for $L"
		if [ ! -d "$PRETRAINED_MODEL_HOME/$L" ]; then
			echo "** ERROR $L do not exist"
			exit 1
		fi

		set -h
		source activate $SYNTAXNET_PYTHON_ENV
		cd "$SYNTAXNET_HOME"
		echo "$APPARG" | syntaxnet/models/parsey_universal/parse.sh "$PRETRAINED_MODEL_HOME/$L"
		source deactivate $SYNTAXNET_PYTHON_ENV
		set +h
	fi
fi


# ------------- SYNTAXNET ----------------------------
if [ "$DOMAIN" == "syntaxnet" ]; then
	if [ "$ACTION" == "install" ]; then
		echo "** Install requirements"
		$STELLA_API get_features

		echo "** Install python & packages"
		conda create -y -n $SYNTAXNET_PYTHON_ENV python=$SYNTAXNET_PYTHON_VERSION

		set -h

		source activate $SYNTAXNET_PYTHON_ENV
		pip install -U protobuf==3.0.0b2
		pip install asciitree
		pip install numpy
		source deactivate $SYNTAXNET_PYTHON_ENV
		set +h

		echo "** Get syntaxnet code source"
		mkdir -p "$TENSORFLOW_MODELS_HOME"
		cd "$TENSORFLOW_MODELS_HOME"
		git clone --recursive https://github.com/tensorflow/models.git
	fi

	if [ "$ACTION" == "build" ]; then
		echo "** Building syntaxnet"
		set -h
		source activate $SYNTAXNET_PYTHON_ENV

		# BUG : switch repo for gmock
		# https://github.com/tensorflow/models/issues/314
		sed -i.bak 's,https://archive.openswitch.net/gmock-1.7.0.zip,http://pkgs.fedoraproject.org/repo/pkgs/gmock/gmock-1.7.0.zip/073b984d8798ea1594f5e44d85b20d66/gmock-1.7.0.zip,' "$TENSORFLOW_MODELS_HOME/models/syntaxnet/tensorflow/tensorflow/workspace.bzl"

		# BUG : when using swig installed in non standard location
		# https://github.com/tensorflow/tensorflow/issues/706
		# https://groups.google.com/forum/#!msg/bazel-discuss/FrHiyndAtik/HAbZBGGXFQ
		# http://codegists.com/code/install-tensorflow-aws/
		# patch tensorflow.bzl
		sed -i.bak 's/ctx.action(executable=ctx.executable.swig_binary,/ctx.action(use_default_shell_env=True,executable=ctx.executable.swig_binary,/' "$TENSORFLOW_MODELS_HOME/models/syntaxnet/tensorflow/tensorflow/tensorflow.bzl"



		cd "$TENSORFLOW_MODELS_HOME/models/syntaxnet/tensorflow"
		./configure

		cd ..

		[ "$FORCE" == "1" ] && bazel clean

		[ "$STELLA_CURRENT_PLATFORM" == "linux" ] && bazel test \
																								--sandbox_debug --verbose_failures \
																								syntaxnet/... util/utf8/...

		[ "$STELLA_CURRENT_PLATFORM" == "darwin" ] && bazel test --linkopt=-headerpad_max_install_names \
																									--sandbox_debug --verbose_failures \
																									syntaxnet/... util/utf8/...

		source deactivate $SYNTAXNET_PYTHON_ENV
		set +h
	fi

	if [ "$ACTION" == "uninstall" ]; then
		$STELLA_API del_folder "$STELLA_APP_WORK_ROOT"
		$STELLA_API del_folder "$TENSORFLOW_MODELS_HOME"
	fi

	if [ "$ACTION" == "test" ]; then
		set -h
		source activate $SYNTAXNET_PYTHON_ENV
		cd "$SYNTAXNET_HOME"
		echo 'Bob brought the pizza to Alice.' | syntaxnet/demo.sh
		source deactivate $SYNTAXNET_PYTHON_ENV
		set +h
	fi


fi
