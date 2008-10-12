BEGIN {
  Forest_id = 0;
}

# returns a new tree_id.
# child_left and child_right are optional.
function new_tree(data,  child_left,  child_right){
  Forest_id++;
  Forest_data[Forest_id] = data;
  Forest_left[Forest_id] = child_left?child_left:0;
  Forest_right[Forest_id] = child_right?child_right:0;
  return Forest_id;
}

# recursive is optional.
function delete_tree(tree_id, recursive){
  if(!tree_id) return;
  if(recursive){
    delete_tree(tree_get_left(tree_id), recursive);
    delete_tree(tree_get_right(tree_id), recursive);
  }
  delete Forest_left[tree_id];
  delete Forest_right[tree_id];
  delete Forest_data[tree_id];
  for(key in Forest_meta_keys)
    if((tree_id, key) in Forest_meta){
      delete Forest_meta[tree_id, key];
      Forest_meta_keys[key]--;
      if(!Forest_meta_keys[key])
	delete Forest_meta_keys[key];
    }
}

# indent is optional.
function dump_tree(tree_id, indent){
  print indent "id: " tree_id;
  print indent "data: " tree_get_data(tree_id);
  for(key in Forest_meta_keys)
    if((tree_id, key) in Forest_meta)
      print indent "meta[" key "]: " Forest_meta[tree_id, key];
  if(tree_get_left(tree_id)){
    print indent "left:";
    dump_tree(tree_get_left(tree_id), indent "  ");
  } else {
    print indent "left: 0";
  }
  if(tree_get_right(tree_id)){
    print indent "right:";
    dump_tree(tree_get_right(tree_id), indent "  ");
  } else {
    print indent "right: 0";
  }
}

function tree_get_left(tree_id){ return Forest_left[tree_id]; }
function tree_set_left(tree_id, child_id){ Forest_left[tree_id] = child_id; }

function tree_get_right(tree_id){ return Forest_right[tree_id]; }
function tree_set_right(tree_id, child_id){ Forest_right[tree_id] = child_id; }

function tree_get_data(tree_id){ return Forest_data[tree_id]; }
function tree_set_data(tree_id, data){ Forest_data[tree_id] = data; }

function tree_get_meta(tree_id, key){ return Forest_meta[tree_id, key]; }
function tree_set_meta(tree_id, key, val){
  if(!((tree_id, key) in Forest_meta)){
    Forest_meta_keys[key]++;
  }
  Forest_meta[tree_id, key] = val;
}
