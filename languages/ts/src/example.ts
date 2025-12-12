import { send_progress, ProgressState } from "./terminal_progress"

function sleep_seconds(seconds: number): Promise<void> {
	return new Promise<void>((resolve) => setTimeout(resolve, seconds * 1000.0))
}

async function main(): Promise<void> {
	const percentage: number = 100

	send_progress({ type: ProgressState.ProgressStateRemove })

	{
		const steps: number = 50
		console.error("Indeterminate progress bar for 2 seconds\n")
		// set the normal progress, o that color is used
		send_progress({ type: ProgressState.ProgressStateSet, value: 10 })

		for (let i = 0; i <= steps; ++i) {
			send_progress({ type: ProgressState.ProgressStateIndeterminate })

			await sleep_seconds(2.0 / steps)
		}
	}

	send_progress({ type: ProgressState.ProgressStateRemove })

	{
		console.error("Progress bar from 0%% to 100%% in 5 seconds\n")

		for (let i = 0; i <= percentage; ++i) {
			send_progress({ type: ProgressState.ProgressStateSet, value: i })

			await sleep_seconds(5.0 / percentage)
		}
	}

	send_progress({ type: ProgressState.ProgressStateRemove })

	{
		const steps = 50
		console.error("Error progress bar for 2 seconds\n")

		for (let i = 0; i <= steps; ++i) {
			send_progress({
				type: ProgressState.ProgressStateError,
				value: undefined,
			})

			await sleep_seconds(2.0 / steps)
		}
	}

	send_progress({ type: ProgressState.ProgressStateRemove })

	{
		console.error("Progress bar error from 0%% to 100%% in 5 seconds\n")

		for (let i = 0; i <= percentage; ++i) {
			send_progress({ type: ProgressState.ProgressStateError, value: i })

			await sleep_seconds(5.0 / percentage)
		}
	}

	send_progress({ type: ProgressState.ProgressStateRemove })

	{
		const steps = 50
		console.error("Paused progress bar for 2 seconds\n")

		for (let i = 0; i <= steps; ++i) {
			send_progress({
				type: ProgressState.ProgressStatePaused,
				value: undefined,
			})

			await sleep_seconds(2.0 / steps)
		}
	}

	send_progress({ type: ProgressState.ProgressStateRemove })

	{
		console.error("Progress bar paused from 0%% to 100%% in 5 seconds\n")

		for (let i = 0; i <= percentage; ++i) {
			send_progress({
				type: ProgressState.ProgressStatePaused,
				value: i,
			})

			await sleep_seconds(5.0 / percentage)
		}
	}

	send_progress({ type: ProgressState.ProgressStateRemove })
}
