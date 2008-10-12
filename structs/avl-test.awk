#returns tree_id.
function abb_insert(tree_id, data){
  if(!tree_id)
    return new_tree(data);
  if(tree_get_data(tree_id)<=data)
    tree_set_left(tree_id, abb_insert(tree_get_left(tree_id), data));
  else
    tree_set_right(tree_id, abb_insert(tree_get_right(tree_id), data));
  return tree_id;
}

BEGIN {
  tree=0;
}

{
  tree = AVL_insert(tree, $0);
}

END {
  dump_tree(tree);
}
