function person_color(p)
   
    person = collect(p)[1]
    if person.health_status == 0
        return :blue
    elseif person.health_status == 1
       return :orange 
    elseif person.health_status == 2
       return :red 
    else
       return :black 
   end
end

function person_shape(p)
    person = collect(p)[1]
    if person.group == 0 # avg;
        return :rect 
    elseif person.group == 1 # low-contact (fearful)
        return :xcross 
    elseif person.group == 2 # high-contact (crazy)
        return :star5
    else
        return
    end
end