=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

#+---------------------+--------------+------+-----+---------------------+----------------+
#| Field               | Type         | Null | Key | Default             | Extra          |
#+---------------------+--------------+------+-----+---------------------+----------------+
#| id                  | int(11)      | NO   | PRI | NULL                | auto_increment |
#| run_id              | int(11)      | NO   | MUL | 0                   |                |
#| user_info_run_id    | int(11)      | NO   | MUL | 0                   |                |
#| configurable_run_id | int(11)      | NO   | MUL | 0                   |                |
#| configurable_type   | varchar(255) | NO   | MUL |                     |                |
#| name                | varchar(255) | YES  | MUL | NULL                |                |
#| value               | varchar(255) | YES  |     | NULL                |                |
#| description         | varchar(255) | YES  |     | NULL                |                |
#| created_by          | int(11)      | YES  |     | NULL                |                |
#| deleted_by          | int(11)      | YES  |     | NULL                |                |
#| created_at          | datetime     | NO   |     | 2001-04-01 00:00:00 |                |
#| since               | datetime     | NO   |     | 2001-04-01 00:00:00 |                |
#| deleted_at          | datetime     | NO   |     | 9999-12-31 23:59:59 |                |
#| till                | datetime     | NO   |     | 9999-12-31 23:59:59 |                |
#| seq                 | varchar(255) | YES  |     | NULL                |                |
#| fullseq             | longtext     | YES  |     | NULL                |                |
#| fullseq_sub         | longtext     | YES  |     | NULL                |                |
#| fullname            | varchar(255) | YES  |     | NULL                |                |
#| merged_to           | int(11)      | YES  |     | NULL                |                |
#| split_from          | int(11)      | YES  |     | NULL                |                |
#+---------------------+--------------+------+-----+---------------------+----------------+

class PersonalConfig < Run
    set_table_name "personal_configs"
end
