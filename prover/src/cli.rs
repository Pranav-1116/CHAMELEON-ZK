use clap::Parser;
use clap::Subcommand;

#[derive(Parser)]
#[command(name = "chameleon")]
#[command(version = "0.1.0")]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    Status,

    Prove {
        #[arg(short, long, default_value = "bn254")]
        backend: String,

        #[arg(short, long, default_value = "3")]
        a: u64,

        #[arg(short = 'B', long, default_value = "7")]
        b: u64,

        #[arg(short, long, default_value = "proof.json")]
        output: String,
    },

    Verify {
        #[arg(short, long, default_value = "proof.json")]
        proof: String,
    },

    Morph {
        #[arg(short, long)]
        to: String,
    },

    Benchmark {
        #[arg(short, long, default_value = "1")]
        iterations: u32,
    },

    Simulate {
        #[arg(short, long, default_value = "quantum")]
        threat: String,

        #[arg(short, long, default_value = "80")]
        level: u32,
    },
}
