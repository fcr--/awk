BEGIN {
  AVL_inc_h = 0;
}

# Left-Left Rotation:
#
#      tree           tree    >   new_root
#     /    \         /    \   >     /  \
#new_root   C   new_root   C  >    A    tree
#  /  \           /  \        >   ---   /  \
# A    B         A    B       >        B    C
#               ---           >
function AVL_rotateLL(tree,
  new_root){
  new_root = tree_get_left(tree)
  tree_set_left(tree, tree_get_right(new_root))
  tree_set_right(new_root, tree)
  tree_set_meta(tree, "fb", 0)
  tree_set_meta(new_root, "fb", 0)
  return new_root
}

function AVL_rotateRR(tree,
  new_root){
  new_root = tree_get_right(tree)
  tree_set_right(tree, tree_get_left(new_root))
  tree_set_left(new_root, tree)
  tree_set_meta(tree, "fb", 0)
  tree_set_meta(new_root, "fb", 0)
  return new_root
}

function AVL_rotateLR(tree,
  fb){
  fb = tree_get_meta(tree_get_right(tree_get_left(tree)), "fb");
  tree_set_left(tree, AVL_rotateRR(tree_get_left(tree)));
  tree = AVL_rotateLL(tree);
  if(fb<0) tree_set_meta(tree_get_left(tree), "fb", 1);
  else if(fb>0) tree_set_meta(tree_get_right(tree), "fb", -1);
  # else it's a small tree like (3, 1, 2)
  return tree
}

function AVL_rotateRL(tree,
  fb){
  fb = tree_get_meta(tree_get_left(tree_get_right(tree)), "fb");
  tree_set_right(tree, AVL_rotateLL(tree_get_left(tree)));
  tree = AVL_rotateRR(tree);
  if(fb<0) tree_set_meta(tree_get_left(tree), "fb", 1);
  else if(fb>0) tree_set_meta(tree_get_right(tree), "fb", -1);
  # else it's a small tree like (1, 3, 2)
  return tree
}

function AVL_insert(tree_id, data,
  tmp, fb){
  if(!tree_id){
    tmp = new_tree(data);
    tree_set_meta(tmp, "fb", 0);
    AVL_inc_h = 1;
    return tmp;
  }
  fb = tree_get_meta(tree_id, "fb");
  if(tree_get_data(tree_id)>=data){
    # Left:
    tmp = AVL_insert(tree_get_left(tree_id), data);
    tree_set_left(tree_id, tmp);
    if(AVL_inc_h){
      if(fb==-1){ # Alt(T->left) < Alt(T->right)
	AVL_inc_h = 0;
	tree_set_meta(tree_id, "fb", 0);
      } else if(fb==0){
	tree_set_meta(tree_id, "fb", 1);
      } else if(fb==1){
        if(tree_get_meta(tmp, "fb")==1)
          tree_id = AVL_rotateLL(tree_id);
	else
          tree_id = AVL_rotateLR(tree_id);
	AVL_inc_h = 0
      }
    }
  } else {
    # Right:
    tmp = AVL_insert(tree_get_right(tree_id), data);
    tree_set_right(tree_id, tmp);
    if(AVL_inc_h){
      if(fb==1){ # Alt(T->left) > Alt(T->right)
	AVL_inc_h = 0
	tree_set_meta(tree_id, "fb", 0)
      } else if(fb==0){
	tree_set_meta(tree_id, "fb", -1)
      } else if(fb==-1){
        if(tree_get_meta(tmp, "fb")==-1)
          tree_id = AVL_rotateRR(tree_id)
	else
          tree_id = AVL_rotateRL(tree_id)
	AVL_inc_h = 0
      }
    }
  }
  return tree_id;
}
