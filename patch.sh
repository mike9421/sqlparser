shopt -s nullglob

COMMON_PATH=$(cd "$(dirname $0)/.."; pwd)

VITESS=$COMMON_PATH/vitess/go/
XWB1989=$COMMON_PATH/sqlparser/

# Create patches for everything that changed
LASTIMPORT=1b7879cb91f1dfe1a2dfa06fea96e951e3a7aec5
for path in ${VITESS?}/{vt/sqlparser,sqltypes,bytes2,hack}; do
	cd ${path}
	git format-patch ${LASTIMPORT?} .
done;

ls ${VITESS?}/{sqltypes,bytes2,hack} &> /dev/null
if [ $? -ne 0 ];then
  ls ${VITESS?}/{sqltypes,bytes2,hack} > /dev/null
  git am --quit
  exit 0
fi

patch_files=$(find ${VITESS?}/{sqltypes,bytes2,hack} -name "*.[patch]" -type f | wc -l)
if [ $patch_files -eq 0 ];then
  echo "there is no need to patch"
  git am --quit
  exit 0
fi

# Apply patches to the dependencies
cd ${XWB1989?}
git am --directory dependency -p2 ${VITESS?}/{sqltypes,bytes2,hack}/*.patch

# Apply the main patches to the repo
cd ${XWB1989?}
git am -p4 ${VITESS?}/vt/sqlparser/*.patch

# If you encounter diff failures, manually fix them with
patch -p4 < .git/rebase-apply/patch

git add name_of_files
git am --continue

# Cleanup
rm ${VITESS?}/{sqltypes,bytes2,hack}/*.patch ${VITESS?}/*.patch

# and Finally update the LASTIMPORT in this README.
