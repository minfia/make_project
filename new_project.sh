#!/usr/bin/env bash


PROGRAM=$(basename $0)

SUPPORTED_LANG=("c" "python")

LANGUAGE="c"
OUTPUT_DIR="."
PROJCT_NAME=""
ENCODING="utf-8"
LF_CODE="lf"


function main()
{
  if [ $# -eq 0 ]; then
    usage
    exit 0
  fi


  parse_args $@

  if [ "$PROJCT_NAME" == "" ]; then
    echo -e "\033[31mError: Please input project name.\033[m"
    exit 1
  fi

  nkf --help &> /dev/null
  if [ $? != 0 ]; then
    echo -e "\033[31mError: Please install 'nkf'."
    exit 1
  fi

  doxygen --help &> /dev/null
  if [ $? != 0 ]; then
    echo -e "\033[31mError: Please install doxygen."
    exit 1
  fi

#  echo "select lauguage $LANGUAGE"
#  echo "output dir = $OUTPUT_DIR"
#  echo "project name = $PROJCT_NAME"
#  echo "encoding = $ENCODING"

  if [ $LANGUAGE == "python" ] && [ $ENCODING == "sjis" ]; then
    echo "$LANGUAGE and $ENCODING is don't exist combination."
    exit 1
  fi

  PROJ_DIR=$OUTPUT_DIR/$PROJCT_NAME
  mkdir $PROJ_DIR
  if [[ $? != 0 ]]; then
    exit 1
  fi

  SRCDIR=$OUTPUT_DIR/$PROJCT_NAME/src
  mkdir $SRCDIR
  if [[ $? != 0 ]]; then
    exit 1
  fi

  case $LANGUAGE in
    c )
      make_main_file_c
      ;;
    python )
      make_main_file_python
      ;;
  esac

  makefile_configure
  gitignore_configure
  readme_configure
  doxygen_configure

  cd $PROJ_DIR
  git init
  git add .
  git commit -m "Initial commit"

  echo ""
  echo "make project done."
}

function parse_args()
{
  while [ -n "$1" ]
  do
    case $1 in
      --lang )
        if [[ ! "$2" =~ ^-+ ]]; then
          # 引数あり
          LANGUAGE=""
          for LANG in ${SUPPORTED_LANG[@]}
          do
            if [[ "$2" == "$LANG" ]]; then
              LANGUAGE=$LANG
              shift
              break
            fi
          done
          if [[ "$LANGUAGE" == "" ]]; then
            echo -e "\033[31mError: specipy lauguage error.\033[m"
            exit 1
          fi
        fi
        ;;
      -o | --output )
        if [[ ! "$2" =~ ^-+ ]]; then
          # 引数あり
          if [[ "$2" == "" ]]; then
            echo -e "\033[31mError: specipy output directory error.\033[m"
            exit 1
          fi
          OUTPUT_DIR=$2
          while true
          do
            if [ "/" == "${OUTPUT_DIR: -1}" ]; then
              OUTPUT_DIR=${OUTPUT_DIR/%?/}
            else
              break
            fi
          done
          shift
        fi
        ;;
      -e | --encoding )
        if [[ ! "$2" =~ ^-+ ]]; then
          # 引数あり
          if [[ "$2" == "" ]]; then
            echo -e "\033[31mError: specipy encoding error.\033[m"
            exit 1
          fi
          case $2 in
            utf-8 | sjis )
              ENCODING=$2
              ;;
            * )
              echo -e "\033[31mError: select encoding is 'utf-8' or 'sjis'.\033[m"
              exit 1
          esac
        fi
        shift
        ;;
      --lf )
        if [[ ! "$2" =~ ^-+ ]]; then
          # 引数あり
          if [[ "$2" == "" ]]; then
            echo -e "\033[31mError: specipy LineFeed error.\033[m"
            exit 1
          fi
          case $2 in
            lf | cr | crlf )
              LF_CODE=$2
              ;;
            * )
              echo -e "\033[31mError: select encoding is 'lf', 'cr' or 'crlf'.\033[m"
              exit 1
          esac
        fi
        shift
        ;;
      -h | --help )
        usage
        exit 0
        ;;
      * )
        if [[ "$1" =~ ^-+ ]] || [ "$PROJCT_NAME" == "" ]; then
          echo -e "\033[31mError: project name error.\033[m"
          exit 1
        fi
        PROJCT_NAME=$1
    esac
    shift
  done
}

# Makefileの設定
function makefile_configure()
{
  local MAKEFILE=$PROJ_DIR/Makefile

  echo -e "# プログラム名\nPROG := $PROJCT_NAME\n" > $MAKEFILE
  echo -e ".PHONY: all clean run doxy doxy_clean\n" >> $MAKEFILE
  echo -e "# ディレクトリ\nSRCDIR := ./src\nOBJDIR := ./obj\nOUTDIR := ./bin\n" >> $MAKEFILE
  echo -e "# ツール設定" >> $MAKEFILE

  case $LANGUAGE in
    c )
      echo -e "CC := gcc\nCFLAGS := -Wall -Wextra\n" >> $MAKEFILE
      echo -e "# ファイル" >> $MAKEFILE
      echo -e "SRCS := \$(shell find \$(SRCDIR) -type f -name *.c)" >> $MAKEFILE
      echo -e "OBJS := \$(subst \$(SRCDIR),\$(OBJDIR),\$(SRCS:%.c=%.o))" >> $MAKEFILE
      echo -e "DEPS := \$(OBJS:%.o=%.d)\n" >> $MAKEFILE
      echo -e "# ビルド設定\nBUILD = debug" >> $MAKEFILE
      echo -e "ifeq (\$(BUILD), release)\nCFLAGS += -Os" >> $MAKEFILE
      echo -e "else ifeq (\$(BUILD), debug)\nCFLAGS += -O0 -g" >> $MAKEFILE
      echo -e "else\n\$(error BUILD=release or debug)\nendif\n" >> $MAKEFILE
      echo -e "all : \$(PROG)\n" >> $MAKEFILE
      echo -e "\$(PROG) : \$(patsubst %, %, \$(OBJS))\n\t@mkdir -p \$(OUTDIR)\n\t\$(CC) \$(CFLAGS) -o \$(OUTDIR)/\$@ \$^\n" >> $MAKEFILE
      echo -e "\$(OBJDIR)/%.o : \$(SRCDIR)/%.c\n\t@mkdir -p \$(dir \$(OBJS))\n\t\$(CC) \$(CFLAGS) -c -MMD -MP -o \$@ \$<\n" >> $MAKEFILE
      echo -e "run :\n\t@\$(OUTDIR)/\$(PROG)\n" >> $MAKEFILE
      echo -e "clean :\n\t@rm -rf \$(OUTDIR) \$(OBJDIR)\n" >> $MAKEFILE
      echo -e "-include \$(DEPS)\n" >> $MAKEFILE
      ;;
    python )
      echo -e "PYTHON :=\nPYINST :=" >> $MAKEFILE
      echo -e "PYTHONW := python3.exe\nPYINSTW := pyinstaller.exe" >> $MAKEFILE
      echo -e "PYTHONL := python3\nPYINSTL := pyinstaller\nPIFLAGS := --onefile --clean\n" >> $MAKEFILE
      echo -e "# ファイル\nSRCS := main.py\n" >> $MAKEFILE
      echo -e "# ビルド設定\nBUILD = release\n" >> $MAKEFILE
      echo -e "ifeq (\$(BUILD), release)\nPIFLAGS += " >> $MAKEFILE
      echo -e "else ifeq (\$(BUILD), debug)\nPIFLAGS += --debug all" >> $MAKEFILE
      echo -e "else\n\$(error BUILD=release or debug)\nendif\n" >> $MAKEFILE
      echo -e "# 実行OS\nOS = linux" >> $MAKEFILE
      echo -e "ifeq (\$(OS), win)\nPYTHON = \$(PYTHONW)\nPYINST = \$(PYINSTW)" >> $MAKEFILE
      echo -e "else ifeq (\$(OS), linux)\nPYTHON = \$(PYTHONL)\nPYINST = \$(PYINSTL)" >> $MAKEFILE
      echo -e "else\n\$(error OS=win or linux)\nendif\n" >> $MAKEFILE
      echo -e "all : \$(PROG)\n" >> $MAKEFILE
      echo -e "\$(PROG) :\n\t\$(PYINST) \$(PIFLAGS) --workpath \$(OBJDIR) --distpath \$(OUTDIR) \$(SRCDIR)/\$(SRCS)\n\t@rename 's/main*/\$@/' \$(OUTDIR)/*\n" >> $MAKEFILE
      echo -e "run :\n\t@\$(PYTHON) \$(SRCDIR)/\$(SRCS)\n" >> $MAKEFILE
      echo -e "clean :\n\t@rm -rf \$(OUTDIR) \$(OBJDIR)\n\t@rm -rf \$(shell find \$(SRCDIR) -type d -name __pycache__)\n" >> $MAKEFILE
      ;;
  esac

  echo -e "# Doc生成\ndoxy :\n\tdoxygen\n" >> $MAKEFILE
  echo -e "# Doc削除\ndoxy_clean:\n\t@rm -rf docs\n" >> $MAKEFILE
}

# DoxygenFileの設定
function doxygen_configure()
{
  local DOXYFILE=$PROJ_DIR/Doxyfile

  doxygen -g $DOXYFILE
  if [ $? -ne 0 ]; then
    echo "Faild to make $DOXYFILE"
    return
  fi

  # 基本設定
  sed -i -e "s/\"My Project\"/\"$PROJCT_NAME\"/" $DOXYFILE
  sed -i -e "s/= English/= Japanese/" $DOXYFILE
  sed -i -e "s/\(OUTPUT_DIRECTORY \+=\)/\1 docs/" $DOXYFILE

  # 言語最適化設定
  if [ $LANGUAGE == "python" ]; then
    sed -i -e "s/^\(OPTIMIZE_OUTPUT_JAVA \+= \)NO/\1YES/" $DOXYFILE
  fi

  # 表示設定
  local EXTRACT_NO_TO_YES=("ALL" "PRIVATE" "STATIC" "LOCAL_METHODS")
  for ITEM in ${EXTRACT_NO_TO_YES[@]}
  do
    sed -i -e "s/^\(EXTRACT_$ITEM \+= \)NO/\1YES/" $DOXYFILE
  done

  # ソースコード文字コード設定
  sed -i -e "s/^\(INPUT \+=\)/\1 .\/src\//" $DOXYFILE
  if [ $ENCODING == "sjis" ]; then
    sed -i -e "s/^\(INPUT_ENCODING \+= \)UTF-8/\1CP932/" $DOXYFILE
  fi

  # ドキュメント化除外設定
  if [ $LANGUAGE == "c" ]; then
    sed -i -e "s/^\(EXCLUDE_PATTERNS \+=\)/\1 \*\/lib\/\*/" $DOXYFILE
  fi

  # HTML設定
  sed -i -e "s/^\(GENERATE_TREEVIEW \+= \)NO/\1YES/" $DOXYFILE

  # LaTeX無効化
  sed -i -e "s/^\(GENERATE_LATEX \+= \)YES/\1NO/" $DOXYFILE
}

# README.mdの設定
function readme_configure()
{
  local README=$PROJ_DIR/README.md

  echo -e "# $PROJCT_NAME project\n\n" > $README
  echo -e "## 環境\n| No. | 名称 | バージョン | 備考 |\n| --- | ---- | ---------- | ---- |\n" >> $README
  echo -e "## 機能\n\n" >> $README
  echo -e "## ビルド" >> $README
  echo -e '```' >> $README
  echo -e "\$ make" >> $README
  echo -e '```\n' >> $README
  echo -e "## 実行" >> $README
  echo -e '```' >> $README
  echo -e "\$ make run" >> $README
  echo -e '```' >> $README
}

# .gitignoreの設定
function gitignore_configure()
{
  local GITIGNORE=$PROJ_DIR/.gitignore

  echo -e "bin/" > $GITIGNORE
  echo -e "obj/" >> $GITIGNORE

  case $LANGUAGE in
    c )
      echo -e "G*" >> $GITIGNORE
      echo -e "html/" >> $GITIGNORE
      ;;
    python )
      echo -e "__pycache__/" >> $GITIGNORE
      echo -e "*.swp" >> $GITIGNORE
      ;;
  esac
}

# C言語プロジェクト設定
function make_main_file_c()
{
  local MAIN_FILE=$SRCDIR/main.c
  echo -e "/**" > $MAIN_FILE
  echo -e " * @file    main.c" >> $MAIN_FILE
  echo -e " * @brief   メインファイル" >> $MAIN_FILE
  echo -e " */\n\n" >> $MAIN_FILE
  echo -e "#include <stdio.h>\n\n" >> $MAIN_FILE
  echo -e "int main(int argc, char *argv[])\n{" >> $MAIN_FILE
  echo -e "    printf(\"Hello world.\\\n\");" >> $MAIN_FILE
  echo -e "    return 0;\n}" >> $MAIN_FILE

  TENC=
  TLF=
  if [ $ENCODING == "sjis" ]; then
    TENC="-s"
  fi

  if [ $LF_CODE == "cr" ]; then
    TLF="m"
  elif [ $LF_CODE == "crlf" ]; then
    TLF="w"
  fi

  if [ "$TENC" != "" ] || [ "$TLF" != "" ]; then
    nkf -L$TLF $TENC --overwrite $MAIN_FILE
  fi
}

# Pythonプロジェクト設定
function make_main_file_python()
{
  local MAIN_FILE=$SRCDIR/main.py
  echo -e "# -*- coding: utf-8 -*-\n\n" > $MAIN_FILE
  echo -e "def main():" >> $MAIN_FILE
  echo -e "    print(\"Hello world.\")\n\n" >> $MAIN_FILE
  echo -e "if __name__ == '__main__':" >> $MAIN_FILE
  echo -e "    main()" >> $MAIN_FILE
}

function usage()
{
  echo -e "Usage: $PROGRAM PROJECTNAME [Options]..."
  echo -e "This script is make new project."
  echo -e "Options:"
  echo -e "  --lang          use language type (default c)"
  echo -e "                  support language list:"

  local LANG_LIST=""
  local CNT=0
  for LANG in ${SUPPORTED_LANG[@]}
  do
    if [ `expr $CNT % 10` -eq 0 ] && [ $CNT -ne 0 ]; then
      LANG_LIST="${LANG_LIST}\n                    "
    fi
    LANG_LIST="${LANG_LIST}${LANG} "
    CNT=`expr $CNT + 1`
  done

  echo -e "                    ${LANG_LIST}"
  echo -e "  -o, --output    project dir make destination (default current)"
  echo -e "  -e, --encoding  use encoding type (default utf-8)"
  echo -e "                  support encoding list:"
  echo -e "                    utf-8 sjis"
  echo -e "  --lf            use LineFeed type (default lf)"
  echo -e "                  support encoding list:"
  echo -e "                    lf cr crlf"
  echo -e "  -h, --help      show help"
}


main $@
