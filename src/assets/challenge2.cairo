// ######## Challenge2
#[contract]
mod callme {

    struct Storage {
        is_complete: bool, 
    }

    #[view]
    fn isComplete() -> bool {
        let output=is_complete::read();
        return(output);
    }

    #[external]
    fn callme() {
        is_complete::write(true);
        return();
    }

}