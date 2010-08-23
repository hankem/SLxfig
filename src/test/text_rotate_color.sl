require("xfig");

variable angle, col, tone, files={};
foreach angle ([0, 30, 57.29577951308232])
  foreach col (["blue", "green", "red"])
    foreach tone (["4", ""])
    {
      variable q = struct { color=col+tone };
      if(angle>0)  q = struct { @q, rotate=angle };
      variable fname = "rotate"+string(angle)+"-"+col+tone;
      message("Trying "+fname+"...");
      try { variable t = xfig_new_text(fname;; q); }
      catch AnyError: { message("An error occured while creating "+fname); }
      t.render(fname);
      list_append(files, fname);
    }

message("Congratulations; you reached this point!");
message("Nevertheless, check the following files:");
message(strjoin(list_to_array(files), " "));
