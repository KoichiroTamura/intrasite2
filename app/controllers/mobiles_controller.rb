=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

class MobilesController < RunsController
  
  skip_before_filter :login_required

  def index
  end


  def schedules
    input_params = {:schedule_span => SchedulesController::DAY,
                    :mobile => true}
    redirect_to schedules_path(input_params)
  end

  def bus_diagrams
    redirect_to bus_diagrams_path(:mobile => true, :station => BusDiagram::Departure_Options[0])
  end

  def courses
    redirect_to courses_path(:mobile => true)
  end

  private

end
